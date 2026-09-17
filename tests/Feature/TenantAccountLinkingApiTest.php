<?php

namespace Tests\Feature;

use App\Models\Property;
use App\Models\Unit;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TenantAccountLinkingApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_owner_creates_a_verified_tenant_linked_to_an_active_contract(): void
    {
        $owner = User::factory()->create(['role' => 'owner', 'is_active' => true]);
        $property = Property::create(['owner_id' => $owner->id, 'name' => 'Résidence test', 'type' => 'Immeuble', 'is_private' => false]);
        $unit = Unit::create(['property_id' => $property->id, 'reference' => 'A-01', 'type' => 'Appartement', 'status' => 'available']);

        $response = $this->actingAs($owner)->postJson('/api/units/'.$unit->id.'/tenant', [
            'first_name' => 'Awa',
            'last_name' => 'Dossou',
            'email' => 'awa.dossou@example.com',
            'phone' => '+2290197000001',
            'starts_at' => '2026-09-01',
            'rent_amount' => 150000,
            'due_day' => 5,
        ])->assertCreated()->assertJsonPath('data.contract.status', 'active');

        $tenantId = $response->json('data.tenant.id');
        $this->assertDatabaseHas('users', ['id' => $tenantId, 'role' => 'tenant', 'email' => 'awa.dossou@example.com']);
        $this->assertNotNull(User::findOrFail($tenantId)->email_verified_at);
        $this->assertDatabaseHas('lease_contracts', ['unit_id' => $unit->id, 'owner_id' => $owner->id, 'tenant_id' => $tenantId, 'status' => 'active']);
        $this->assertDatabaseCount('rent_schedules', 12);
        $this->assertSame('occupied', $unit->fresh()->status);
        $this->postJson('/api/auth/login', ['identifier' => 'awa.dossou@example.com', 'password' => 'password'])->assertOk();
    }

    public function test_owner_cannot_attach_a_second_active_tenant_to_the_same_unit(): void
    {
        $owner = User::factory()->create(['role' => 'owner', 'is_active' => true]);
        $property = Property::create(['owner_id' => $owner->id, 'name' => 'Résidence test', 'type' => 'Immeuble', 'is_private' => false]);
        $unit = Unit::create(['property_id' => $property->id, 'reference' => 'A-01', 'type' => 'Appartement', 'status' => 'available']);
        $payload = ['first_name' => 'Awa', 'last_name' => 'Dossou', 'email' => 'awa@example.com', 'phone' => '+2290197000002', 'starts_at' => '2026-09-01', 'rent_amount' => 150000, 'due_day' => 5];
        $this->actingAs($owner)->postJson('/api/units/'.$unit->id.'/tenant', $payload)->assertCreated();

        $this->actingAs($owner)->postJson('/api/units/'.$unit->id.'/tenant', [...$payload, 'email' => 'autre@example.com', 'phone' => '+2290197000003'])
            ->assertStatus(422)
            ->assertJsonPath('message', 'Ce logement possède déjà un contrat actif.');
    }
}
