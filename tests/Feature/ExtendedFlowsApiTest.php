<?php

namespace Tests\Feature;

use App\Models\Conversation;
use App\Models\Event;
use App\Models\Inspection;
use App\Models\LeaseContract;
use App\Models\Listing;
use App\Models\MaintenanceRequest;
use App\Models\Media;
use App\Models\Receipt;
use App\Models\RentSchedule;
use App\Models\TicketType;
use App\Models\User;
use App\Services\ListingAlertService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class ExtendedFlowsApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_public_events_are_future_and_ticket_order_has_payment(): void
    {
        $this->seed();
        $seeker = User::where('role', 'seeker')->firstOrFail();
        $event = Event::where('status', 'published')->firstOrFail();
        $type = TicketType::where('event_id', $event->id)->where('type', 'VIP')->firstOrFail();
        $this->getJson('/api/events')->assertOk()->assertJsonCount(4, 'data.data');
        $order = $this->actingAs($seeker)->postJson('/api/events/'.$event->id.'/orders', ['ticket_type_id' => $type->id, 'quantity' => 2, 'payment_method' => 'mobile_money'])->assertCreated()->assertJsonPath('data.payment.status', 'paid')->json('data');
        $this->assertDatabaseCount('tickets', 4);
        $this->assertDatabaseHas('ticket_payments', ['ticket_order_id' => $order['id'], 'status' => 'paid']);
    }

    public function test_event_cover_is_served_without_a_public_storage_symlink(): void
    {
        $this->seed();
        Storage::fake('public');
        Storage::disk('public')->put('events/cover.jpg', 'event-cover');
        $event = Event::where('status', 'published')->firstOrFail();
        $event->update(['cover_path' => 'events/cover.jpg']);

        $coverUrl = $this->getJson('/api/events/'.$event->id)
            ->assertOk()
            ->json('data.cover_url');

        $this->get($coverUrl)
            ->assertOk()
            ->assertHeader('content-type', 'image/jpeg');
    }

    public function test_seeker_can_apply_and_owner_can_accept(): void
    {
        $this->seed();
        $seeker = User::where('email', 'ruth.chercheur@vimmo.bj')->firstOrFail();
        $listing = Listing::where('status', 'published')
            ->whereHas('unit', fn ($query) => $query->where('status', 'available'))
            ->firstOrFail();
        $application = $this->actingAs($seeker)->postJson('/api/listings/'.$listing->id.'/applications', ['message' => 'Dossier complet'])->assertCreated()->json('data');
        $owner = User::findOrFail($listing->owner_id);
        $this->actingAs($owner)->patchJson('/api/rental-applications/'.$application['id'].'/status', ['status' => 'accepted'])->assertOk()->assertJsonPath('data.status', 'accepted');
    }

    public function test_owner_lists_and_dashboard_include_new_real_estate_requests(): void
    {
        $this->seed();
        $seeker = User::where('email', 'ruth.chercheur@vimmo.bj')->firstOrFail();
        $listing = Listing::where('status', 'published')
            ->whereHas('unit', fn ($query) => $query->where('status', 'available'))
            ->firstOrFail();
        $owner = User::findOrFail($listing->owner_id);

        $visitId = $this->actingAs($seeker)->postJson('/api/listings/'.$listing->id.'/visits', [
            'requested_at' => now()->addDays(2)->toIso8601String(),
            'comment' => 'Je souhaite visiter ce logement.',
        ])->assertCreated()->json('data.id');
        $applicationId = $this->actingAs($seeker)->postJson('/api/listings/'.$listing->id.'/applications', [
            'message' => 'Ma candidature est complète.',
        ])->assertCreated()->json('data.id');

        $this->actingAs($owner)->getJson('/api/visits')
            ->assertOk()
            ->assertJsonFragment(['id' => $visitId, 'requester_email' => $seeker->email]);
        $this->actingAs($owner)->getJson('/api/rental-applications')
            ->assertOk()
            ->assertJsonFragment(['id' => $applicationId, 'applicant_id' => $seeker->id]);
        $dashboard = $this->actingAs($owner)->getJson('/api/dashboard')->assertOk();
        $this->assertGreaterThanOrEqual(1, $dashboard->json('data.pending_visits'));
        $this->assertGreaterThanOrEqual(1, $dashboard->json('data.pending_applications'));
    }

    public function test_owner_can_confirm_a_visit_with_a_new_schedule_and_message(): void
    {
        $this->seed();
        $seeker = User::where('role', 'seeker')->firstOrFail();
        $listing = Listing::where('status', 'published')
            ->whereHas('unit', fn ($query) => $query->where('status', 'available'))
            ->firstOrFail();
        $visit = $this->actingAs($seeker)->postJson('/api/listings/'.$listing->id.'/visits', [
            'requested_at' => now()->addDays(2)->toIso8601String(),
            'comment' => 'Disponible en matinée.',
        ])->assertCreated()->json('data');
        $owner = User::findOrFail($listing->owner_id);
        $proposedAt = now()->addDays(3)->setTime(15, 30)->toIso8601String();

        $this->actingAs($owner)->patchJson('/api/visits/'.$visit['id'].'/status', [
            'status' => 'confirmed',
            'owner_note' => 'Merci de vous présenter dix minutes avant.',
            'proposed_at' => $proposedAt,
        ])->assertOk()
            ->assertJsonPath('data.status', 'confirmed')
            ->assertJsonPath('data.owner_note', 'Merci de vous présenter dix minutes avant.');

        $this->assertDatabaseHas('visit_requests', [
            'id' => $visit['id'],
            'status' => 'confirmed',
            'owner_note' => 'Merci de vous présenter dix minutes avant.',
        ]);
    }

    public function test_rejecting_a_request_requires_a_reason(): void
    {
        $this->seed();
        $seeker = User::where('role', 'seeker')->firstOrFail();
        $listing = Listing::where('status', 'published')
            ->whereHas('unit', fn ($query) => $query->where('status', 'available'))
            ->firstOrFail();
        $application = $this->actingAs($seeker)->postJson('/api/listings/'.$listing->id.'/applications', [
            'message' => 'Mon dossier est disponible.',
        ])->assertCreated()->json('data');
        $owner = User::findOrFail($listing->owner_id);

        $this->actingAs($owner)->patchJson('/api/rental-applications/'.$application['id'].'/status', [
            'status' => 'rejected',
        ])->assertUnprocessable()
            ->assertJsonValidationErrors('owner_note');
    }

    public function test_maintenance_is_limited_to_linked_tenant_and_accepts_comments(): void
    {
        $this->seed();
        $maintenance = MaintenanceRequest::firstOrFail();
        $tenant = User::findOrFail($maintenance->reported_by);
        $this->actingAs($tenant)->postJson('/api/maintenance/'.$maintenance->id.'/comments', ['comment' => 'Nouvelle précision'])->assertCreated();
        $other = User::where('role', 'tenant')->whereKeyNot($tenant->id)->firstOrFail();
        $this->actingAs($other)->getJson('/api/maintenance/'.$maintenance->id)->assertForbidden();
    }

    public function test_owner_status_update_sends_its_message_to_the_tenant(): void
    {
        $this->seed();
        $maintenance = MaintenanceRequest::with('unit.property')->firstOrFail();
        $owner = User::findOrFail($maintenance->unit->property->owner_id);

        $this->actingAs($owner)->patchJson('/api/maintenance/'.$maintenance->id.'/status', [
            'status' => 'processing',
            'owner_message' => 'Un technicien vous contactera dans la journée.',
        ])->assertOk()
            ->assertJsonPath('data.status', 'processing')
            ->assertJsonFragment([
                'comment' => 'Un technicien vous contactera dans la journée.',
            ]);

        $this->assertDatabaseHas('maintenance_comments', [
            'maintenance_request_id' => $maintenance->id,
            'user_id' => $owner->id,
            'comment' => 'Un technicien vous contactera dans la journée.',
        ]);
        $this->assertDatabaseHas('notifications', [
            'user_id' => $maintenance->reported_by,
            'type' => 'maintenance',
        ]);
    }

    public function test_owner_can_preview_a_tenant_complaint_image(): void
    {
        $this->seed();
        Storage::fake('private');
        Storage::disk('private')->put('maintenance/fuite.jpg', 'image-content');
        $maintenance = MaintenanceRequest::with('unit.property')->firstOrFail();
        $owner = User::findOrFail($maintenance->unit->property->owner_id);
        $media = Media::create([
            'user_id' => $maintenance->reported_by,
            'mediable_type' => MaintenanceRequest::class,
            'mediable_id' => $maintenance->id,
            'collection' => 'evidence',
            'disk' => 'private',
            'path' => 'maintenance/fuite.jpg',
            'mime_type' => 'image/jpeg',
            'size' => 13,
            'metadata' => ['original_name' => 'fuite.jpg'],
        ]);

        $this->actingAs($owner)->get('/api/media/'.$media->id.'/preview')
            ->assertOk()
            ->assertHeader('content-type', 'image/jpeg');
    }

    public function test_owner_can_reject_a_maintenance_request_with_a_reason(): void
    {
        $this->seed();
        $maintenance = MaintenanceRequest::with('unit.property')->firstOrFail();
        $owner = User::findOrFail($maintenance->unit->property->owner_id);

        $this->actingAs($owner)->postJson('/api/maintenance/'.$maintenance->id.'/reject', [
            'reason' => 'Le problème ne relève pas du logement.',
        ])->assertOk()
            ->assertJsonPath('data.status', 'closed')
            ->assertJsonPath('data.rejection_reason', 'Le problème ne relève pas du logement.');

        $this->assertDatabaseHas('maintenance_requests', [
            'id' => $maintenance->id,
            'rejection_reason' => 'Le problème ne relève pas du logement.',
        ]);
        $this->assertDatabaseHas('notifications', [
            'user_id' => $maintenance->reported_by,
            'type' => 'maintenance_rejected',
        ]);

        $otherOwner = User::factory()->create(['role' => 'owner']);
        $this->actingAs($otherOwner)->postJson('/api/maintenance/'.$maintenance->id.'/reject', [
            'reason' => 'Tentative interdite.',
        ])->assertForbidden();
    }

    public function test_conversation_list_returns_the_actual_latest_message(): void
    {
        $this->seed();
        $conversation = Conversation::with('participants')->firstOrFail();
        $participant = $conversation->participants->firstOrFail();
        $conversation->messages()->create([
            'sender_id' => $participant->id,
            'body' => 'Réponse la plus récente du propriétaire',
            'type' => 'text',
        ]);
        $conversation->touch();

        $this->actingAs($participant)->getJson('/api/conversations')
            ->assertOk()
            ->assertJsonPath('data.0.latest_message.body', 'Réponse la plus récente du propriétaire');
    }

    public function test_owner_receives_a_message_started_by_a_seeker(): void
    {
        $this->seed();
        $listing = Listing::with('unit')
            ->where('status', 'published')
            ->firstOrFail();
        $seeker = User::where('role', 'seeker')->firstOrFail();
        $owner = User::findOrFail($listing->owner_id);
        $conversationId = $this->actingAs($seeker)->postJson('/api/conversations', [
            'participant_id' => $owner->id,
            'listing_id' => $listing->id,
            'unit_id' => $listing->unit_id,
            'subject' => $listing->title,
        ])->assertSuccessful()->json('data.id');

        $this->actingAs($seeker)->postJson('/api/conversations/'.$conversationId.'/messages', [
            'body' => 'Bonjour, ce logement est-il toujours disponible ?',
        ])->assertCreated();

        $this->actingAs($owner)->getJson('/api/conversations')
            ->assertOk()
            ->assertJsonFragment([
                'id' => $conversationId,
                'body' => 'Bonjour, ce logement est-il toujours disponible ?',
            ]);
        $this->actingAs($owner)->getJson('/api/conversations/'.$conversationId.'/messages')
            ->assertOk()
            ->assertJsonFragment(['body' => 'Bonjour, ce logement est-il toujours disponible ?']);
    }

    public function test_tenant_can_edit_or_delete_only_a_pending_maintenance_request(): void
    {
        $this->seed();
        $maintenance = MaintenanceRequest::firstOrFail();
        $tenant = User::findOrFail($maintenance->reported_by);
        $maintenance->update(['status' => 'received']);

        $this->actingAs($tenant)->patchJson('/api/maintenance/'.$maintenance->id, [
            'category' => 'plomberie',
            'title' => 'Fuite sous l’évier',
            'description' => 'La fuite reste visible lorsque le robinet est fermé.',
            'availability_notes' => 'Disponible à partir de 18 h.',
            'priority' => 'high',
        ])->assertOk()
            ->assertJsonPath('data.title', 'Fuite sous l’évier')
            ->assertJsonPath('data.priority', 'high');

        $maintenance->update(['status' => 'processing']);
        $this->actingAs($tenant)->patchJson('/api/maintenance/'.$maintenance->id, [
            'category' => 'plomberie',
            'title' => 'Titre modifié',
            'description' => 'Description modifiée.',
            'priority' => 'normal',
        ])->assertUnprocessable();
        $this->actingAs($tenant)
            ->deleteJson('/api/maintenance/'.$maintenance->id)
            ->assertUnprocessable();

        $maintenance->update(['status' => 'received']);
        $this->actingAs($tenant)
            ->deleteJson('/api/maintenance/'.$maintenance->id)
            ->assertOk();
        $this->assertDatabaseMissing('maintenance_requests', ['id' => $maintenance->id]);
    }

    public function test_owner_can_read_arrears_and_send_reminder(): void
    {
        $this->seed();
        $contract = LeaseContract::firstOrFail();
        $schedule = RentSchedule::where('lease_contract_id', $contract->id)->firstOrFail();
        $schedule->update(['due_date' => today()->subDays(5), 'status' => 'due', 'paid_amount' => 0]);
        $owner = User::findOrFail($contract->owner_id);
        $this->actingAs($owner)->getJson('/api/arrears')->assertOk()->assertJsonFragment(['id' => $schedule->id]);
        $this->actingAs($owner)->postJson('/api/arrears/'.$schedule->id.'/remind')->assertOk();
        $this->assertDatabaseHas('notifications', ['user_id' => $contract->tenant_id, 'type' => 'rent_reminder']);
    }

    public function test_completed_inspection_generates_real_pdf(): void
    {
        $this->seed();
        $inspection = Inspection::firstOrFail();
        $tenant = User::findOrFail($inspection->contract->tenant_id);
        $response = $this->actingAs($tenant)->get('/api/inspections/'.$inspection->id.'/download');
        $response->assertOk()->assertHeader('content-type', 'application/pdf');
        $this->assertStringStartsWith('%PDF-', $response->getContent());
    }

    public function test_mutations_are_written_to_audit_log(): void
    {
        $this->seed();
        $seeker = User::where('role', 'seeker')->firstOrFail();
        $listing = Listing::where('status', 'published')
            ->whereHas('unit', fn ($query) => $query->where('status', 'available'))
            ->firstOrFail();
        $this->actingAs($seeker)->postJson('/api/listings/'.$listing->id.'/favorite')->assertOk();
        $this->assertDatabaseHas('audit_logs', ['user_id' => $seeker->id, 'action' => 'POST api/listings/{listing}/favorite']);
    }

    public function test_receipt_can_be_verified_publicly_and_unit_timeline_is_scoped(): void
    {
        $this->seed();
        $receipt = Receipt::firstOrFail();
        $this->getJson('/api/receipts/verify/'.$receipt->verification_token)->assertOk()->assertJsonPath('data.reference', $receipt->reference);
        $contract = $receipt->payment->contract;
        $owner = User::findOrFail($contract->owner_id);
        $this->actingAs($owner)->getJson('/api/units/'.$contract->unit_id.'/timeline')->assertOk()->assertJsonPath('data.unit.id', $contract->unit_id);
        $outsider = User::factory()->create(['role' => 'tenant']);
        $this->actingAs($outsider)->getJson('/api/units/'.$contract->unit_id.'/timeline')->assertForbidden();
    }

    public function test_organizer_can_archive_event_without_sales(): void
    {
        $this->seed();
        $event = Event::whereDoesntHave('orders', fn ($query) => $query->where('status', 'paid'))->firstOrFail();
        $organizer = User::findOrFail($event->organizer_id);
        $this->actingAs($organizer)->deleteJson('/api/organizer/events/'.$event->id)->assertOk()->assertJsonPath('data.status', 'suspended');
    }

    public function test_marketplace_filters_french_amenities_and_returns_complete_favorites(): void
    {
        $this->seed();
        $seeker = User::where('role', 'seeker')->firstOrFail();
        $listing = Listing::with('unit')
            ->where('status', 'published')
            ->whereHas('unit', fn ($query) => $query
                ->where('status', 'available')
                ->whereJsonContains('amenities', 'climatisation'))
            ->firstOrFail();

        $this->getJson('/api/listings?air_conditioning=1&availability='.$listing->unit->status)
            ->assertOk()
            ->assertJsonFragment(['id' => $listing->id]);

        $this->actingAs($seeker)->postJson('/api/listings/'.$listing->id.'/favorite')->assertOk();
        $this->actingAs($seeker)->getJson('/api/favorites')
            ->assertOk()
            ->assertJsonPath('data.0.id', $listing->id)
            ->assertJsonStructure(['data' => [['unit' => ['media', 'property' => ['media']], 'owner']]]);
    }

    public function test_seeker_can_toggle_and_delete_a_saved_search(): void
    {
        $this->seed();
        $seeker = User::where('role', 'seeker')->firstOrFail();
        $created = $this->actingAs($seeker)->postJson('/api/saved-searches', [
            'name' => 'Appartement à Cotonou',
            'criteria' => ['type' => 'Appartement', 'city' => 'Cotonou'],
            'alerts_enabled' => true,
        ])->assertCreated();
        $searchId = $created->json('data.id');

        $this->actingAs($seeker)->patchJson('/api/saved-searches/'.$searchId, [
            'alerts_enabled' => false,
        ])->assertOk()->assertJsonPath('data.alerts_enabled', 0);

        $this->actingAs($seeker)->deleteJson('/api/saved-searches/'.$searchId)
            ->assertOk();
        $this->assertDatabaseMissing('saved_searches', ['id' => $searchId]);
    }

    public function test_saved_search_alerts_match_the_same_advanced_filters_as_marketplace(): void
    {
        $this->seed();
        $seeker = User::where('role', 'seeker')->firstOrFail();
        $listing = Listing::with('unit.property')
            ->whereHas('unit', fn ($query) => $query->whereJsonContains('amenities', 'climatisation'))
            ->firstOrFail();
        $this->actingAs($seeker)->postJson('/api/saved-searches', [
            'name' => 'Climatisé à Cotonou',
            'criteria' => [
                'city' => $listing->unit->property->city,
                'air_conditioning' => '1',
                'availability' => $listing->unit->status,
                'max_price' => (float) $listing->price,
            ],
            'alerts_enabled' => true,
        ])->assertCreated();

        \DB::table('notifications')
            ->where('user_id', $seeker->id)
            ->where('type', 'property_alert')
            ->delete();
        app(ListingAlertService::class)->notifyFor($listing);

        $this->assertTrue(\DB::table('notifications')
            ->where('user_id', $seeker->id)
            ->where('type', 'property_alert')
            ->where('data', 'like', '%"listing_id":'.$listing->id.'%')
            ->exists());
    }

    public function test_conversations_are_limited_to_the_users_linked_to_the_property(): void
    {
        $this->seed();
        $listing = Listing::with('unit')->firstOrFail();
        $seeker = User::where('role', 'seeker')->firstOrFail();
        $owner = User::findOrFail($listing->owner_id);

        $this->actingAs($seeker)->postJson('/api/conversations', [
            'participant_id' => $owner->id,
            'listing_id' => $listing->id,
            'unit_id' => $listing->unit_id,
            'subject' => $listing->title,
        ])->assertSuccessful()
            ->assertJsonStructure(['data' => ['unit' => ['media', 'property' => ['media']]]]);

        $unrelatedOwner = User::factory()->create(['role' => 'owner']);
        $this->actingAs($seeker)->postJson('/api/conversations', [
            'participant_id' => $unrelatedOwner->id,
            'listing_id' => $listing->id,
            'unit_id' => $listing->unit_id,
        ])->assertForbidden();
    }
}
