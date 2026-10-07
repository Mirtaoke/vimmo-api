<?php

namespace Tests\Feature;

use App\Models\Listing;
use App\Models\Property;
use App\Models\Unit;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TenantAccountLinkingApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_first_due_date_never_precedes_the_contract_start(): void
    {
        Carbon::setTestNow('2026-10-07 10:00:00');
        $owner = User::factory()->create(['role' => 'owner', 'is_active' => true]);
        $property = Property::create(['owner_id' => $owner->id, 'name' => 'Résidence test', 'type' => 'Immeuble', 'is_private' => false]);
        $unit = Unit::create(['property_id' => $property->id, 'reference' => 'A-01', 'type' => 'Appartement', 'status' => 'available', 'monthly_rent' => 80000]);

        $this->actingAs($owner)->postJson('/api/units/'.$unit->id.'/tenant', [
            'first_name' => 'Awa',
            'last_name' => 'Dossou',
            'email' => 'awa.echeance@example.com',
            'phone' => '+2290197000099',
            'starts_at' => '2026-10-07',
            'due_day' => 5,
        ])->assertCreated();

        $this->assertDatabaseHas('rent_schedules', [
            'due_date' => '2026-11-05 00:00:00',
            'amount' => 80000,
            'status' => 'upcoming',
        ]);
        $this->assertDatabaseMissing('rent_schedules', ['due_date' => '2026-10-05 00:00:00']);
        Carbon::setTestNow();
    }

    public function test_owner_creates_a_verified_tenant_linked_to_an_active_contract(): void
    {
        $owner = User::factory()->create(['role' => 'owner', 'is_active' => true]);
        $property = Property::create(['owner_id' => $owner->id, 'name' => 'Résidence test', 'type' => 'Immeuble', 'is_private' => false]);
        $unit = Unit::create(['property_id' => $property->id, 'reference' => 'A-01', 'type' => 'Appartement', 'status' => 'available', 'monthly_rent' => 175000]);
        $listing = Listing::create([
            'owner_id' => $owner->id,
            'unit_id' => $unit->id,
            'title' => 'Appartement A-01',
            'description' => 'Appartement disponible',
            'price' => 175000,
            'status' => 'published',
            'published_at' => now(),
        ]);

        $response = $this->actingAs($owner)->postJson('/api/units/'.$unit->id.'/tenant', [
            'first_name' => 'Awa',
            'last_name' => 'Dossou',
            'email' => 'awa.dossou@example.com',
            'phone' => '+2290197000001',
            'starts_at' => '2026-09-01',
            'due_day' => 5,
        ])->assertCreated()->assertJsonPath('data.contract.status', 'active');

        $tenantId = $response->json('data.tenant.id');
        $this->assertDatabaseHas('users', ['id' => $tenantId, 'role' => 'tenant', 'email' => 'awa.dossou@example.com']);
        $this->assertNotNull(User::findOrFail($tenantId)->email_verified_at);
        $this->assertDatabaseHas('lease_contracts', ['unit_id' => $unit->id, 'owner_id' => $owner->id, 'tenant_id' => $tenantId, 'rent_amount' => 175000, 'status' => 'active']);
        $this->assertDatabaseCount('rent_schedules', 12);
        $this->assertSame('occupied', $unit->fresh()->status);
        $this->assertSame('rented', $listing->fresh()->status);
        $this->getJson('/api/listings')
            ->assertOk()
            ->assertJsonMissing(['id' => $listing->id]);
        $this->postJson('/api/auth/login', ['identifier' => 'awa.dossou@example.com', 'password' => 'password'])->assertOk();
    }

    public function test_owner_cannot_attach_a_second_active_tenant_to_the_same_unit(): void
    {
        $owner = User::factory()->create(['role' => 'owner', 'is_active' => true]);
        $property = Property::create(['owner_id' => $owner->id, 'name' => 'Résidence test', 'type' => 'Immeuble', 'is_private' => false]);
        $unit = Unit::create(['property_id' => $property->id, 'reference' => 'A-01', 'type' => 'Appartement', 'status' => 'available', 'monthly_rent' => 150000]);
        $payload = ['first_name' => 'Awa', 'last_name' => 'Dossou', 'email' => 'awa@example.com', 'phone' => '+2290197000002', 'starts_at' => '2026-09-01', 'due_day' => 5];
        $this->actingAs($owner)->postJson('/api/units/'.$unit->id.'/tenant', $payload)->assertCreated();

        $this->actingAs($owner)->postJson('/api/units/'.$unit->id.'/tenant', [...$payload, 'email' => 'autre@example.com', 'phone' => '+2290197000003'])
            ->assertStatus(422)
            ->assertJsonPath('message', 'Ce logement possède déjà un contrat actif.');
    }

    public function test_owner_cannot_attach_a_tenant_to_a_family_property(): void
    {
        $owner = User::factory()->create(['role' => 'owner', 'is_active' => true]);
        $property = Property::create(['owner_id' => $owner->id, 'name' => 'Maison familiale', 'type' => 'Maison', 'is_private' => true]);
        $unit = Unit::create(['property_id' => $property->id, 'reference' => 'Maison principale', 'type' => 'Maison', 'status' => 'available', 'monthly_rent' => 0]);

        $this->actingAs($owner)->postJson('/api/units/'.$unit->id.'/tenant', [
            'first_name' => 'Awa',
            'last_name' => 'Dossou',
            'email' => 'awa.famille@example.com',
            'phone' => '+2290197000010',
            'starts_at' => '2026-10-01',
            'rent_amount' => 150000,
            'due_day' => 5,
        ])->assertStatus(422)
            ->assertJsonPath('message', 'Un locataire ne peut être associé qu’à un bien locatif.');

        $this->assertDatabaseMissing('users', ['email' => 'awa.famille@example.com']);
    }
}
