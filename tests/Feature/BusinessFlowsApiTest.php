<?php

namespace Tests\Feature;

use App\Models\Payment;
use App\Models\Receipt;
use App\Models\Ticket;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class BusinessFlowsApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_owner_dashboard_returns_real_portfolio_counters(): void
    {
        $this->seed();
        $owner = User::where('role', 'owner')->firstOrFail();

        $this->actingAs($owner)->getJson('/api/dashboard')
            ->assertOk()
            ->assertJsonStructure(['data' => ['properties', 'rental_properties', 'private_properties', 'units', 'occupied_units', 'tenants', 'active_contracts', 'active_listings', 'pending_payments', 'open_maintenance', 'pending_inspections', 'rent_received', 'rent_received_month', 'rent_due_month', 'rent_collected_for_month', 'collection_rate', 'rent_pending', 'unread_messages', 'unread_notifications']]);
    }

    public function test_new_owner_dashboard_contains_only_zero_values(): void
    {
        $owner = User::factory()->create(['role' => 'owner']);

        $response = $this->actingAs($owner)->getJson('/api/dashboard')->assertOk();

        foreach (['properties', 'rental_properties', 'private_properties', 'units', 'occupied_units', 'tenants', 'active_contracts', 'active_listings', 'pending_payments', 'open_maintenance', 'pending_inspections', 'rent_received', 'rent_received_month', 'rent_due_month', 'rent_collected_for_month', 'collection_rate', 'rent_pending', 'unread_messages', 'unread_notifications'] as $key) {
            $this->assertEquals(0, $response->json('data.'.$key), "La valeur {$key} doit être nulle pour un nouveau propriétaire.");
        }
    }

    public function test_organizer_can_read_sales_and_scan_ticket_only_once(): void
    {
        $this->seed();
        $organizer = User::where('role', 'organizer')->firstOrFail();
        $ticket = Ticket::where('status', 'valid')->firstOrFail();

        $this->actingAs($organizer)->getJson('/api/organizer/sales')
            ->assertOk()->assertJsonPath('success', true)->assertJsonCount(1, 'data');

        $this->actingAs($organizer)->postJson('/api/organizer/tickets/scan', ['code' => $ticket->code])
            ->assertOk()->assertJsonPath('data.status', 'used');
        $this->actingAs($organizer)->postJson('/api/organizer/tickets/scan', ['code' => $ticket->code])
            ->assertStatus(422);
    }

    public function test_owner_confirms_payment_and_tenant_receives_receipt(): void
    {
        $this->seed();
        $owner = User::where('role', 'owner')->firstOrFail();
        $tenant = User::where('role', 'tenant')->firstOrFail();
        $payment = Payment::firstOrFail();
        $payment->update(['status' => 'pending', 'confirmed_by' => null, 'confirmed_at' => null]);

        $this->actingAs($owner)->postJson('/api/payments/'.$payment->id.'/confirm')
            ->assertOk()->assertJsonPath('data.status', 'confirmed');
        $this->actingAs($tenant)->getJson('/api/receipts')
            ->assertOk()->assertJsonPath('success', true)->assertJsonCount(1, 'data');
    }

    public function test_contract_documents_are_visible_to_linked_tenant_only(): void
    {
        $this->seed();
        $tenant = User::where('role', 'tenant')->firstOrFail();
        $other = User::factory()->create(['role' => 'tenant']);

        $this->actingAs($tenant)->getJson('/api/documents')
            ->assertOk()->assertJsonCount(2, 'data');
        $this->actingAs($other)->getJson('/api/documents')
            ->assertOk()->assertJsonCount(0, 'data');
    }

    public function test_owner_can_update_and_delete_an_unleased_property(): void
    {
        $this->seed();
        $owner = User::where('role', 'owner')->firstOrFail();
        $created = $this->actingAs($owner)->postJson('/api/properties', [
            'name' => 'Bien temporaire', 'type' => 'villa', 'city' => 'Cotonou',
        ])->assertCreated()->json('data');

        $this->actingAs($owner)->putJson('/api/properties/'.$created['id'], ['name' => 'Bien corrigé'])
            ->assertOk()->assertJsonPath('data.name', 'Bien corrigé');
        $this->actingAs($owner)->deleteJson('/api/properties/'.$created['id'])
            ->assertOk()->assertJsonPath('success', true);
        $this->assertDatabaseMissing('properties', ['id' => $created['id']]);
    }

    public function test_owner_can_reject_a_pending_payment_with_a_reason(): void
    {
        $this->seed();
        $owner = User::where('role', 'owner')->firstOrFail();
        $payment = Payment::firstOrFail();
        $payment->update(['status' => 'pending', 'confirmed_by' => null, 'confirmed_at' => null]);

        $this->actingAs($owner)->postJson('/api/payments/'.$payment->id.'/reject', ['reason' => 'Justificatif illisible'])
            ->assertOk()->assertJsonPath('data.status', 'rejected');
        $this->assertStringContainsString('Justificatif illisible', $payment->fresh()->note);
        $this->assertDatabaseHas('notifications', [
            'user_id' => $payment->payer_id,
            'type' => 'payment',
            'title' => 'Paiement non validé',
        ]);
    }

    public function test_linked_tenant_can_download_a_real_pdf_receipt(): void
    {
        $this->seed();
        $tenant = User::where('role', 'tenant')->firstOrFail();
        $receipt = Receipt::firstOrFail();

        $response = $this->actingAs($tenant)->get('/api/receipts/'.$receipt->id.'/download');
        $response->assertOk()->assertHeader('content-type', 'application/pdf');
        $this->assertStringStartsWith('%PDF-', $response->getContent());
    }
}
