<?php

namespace Tests\Feature;

use App\Models\Event;
use App\Models\Inspection;
use App\Models\LeaseContract;
use App\Models\Listing;
use App\Models\MaintenanceRequest;
use App\Models\Receipt;
use App\Models\RentSchedule;
use App\Models\TicketType;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
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

    public function test_seeker_can_apply_and_owner_can_accept(): void
    {
        $this->seed();
        $seeker = User::where('email', 'ruth.chercheur@vimmo.bj')->firstOrFail();
        $listing = Listing::firstOrFail();
        $application = $this->actingAs($seeker)->postJson('/api/listings/'.$listing->id.'/applications', ['message' => 'Dossier complet'])->assertCreated()->json('data');
        $owner = User::findOrFail($listing->owner_id);
        $this->actingAs($owner)->patchJson('/api/rental-applications/'.$application['id'].'/status', ['status' => 'accepted'])->assertOk()->assertJsonPath('data.status', 'accepted');
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
        $listing = Listing::firstOrFail();
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
        $this->actingAs($organizer)->deleteJson('/api/organizer/events/'.$event->id)->assertOk()->assertJsonPath('data.status','suspended');
    }
}
