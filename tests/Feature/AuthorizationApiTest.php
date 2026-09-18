<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthorizationApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_seeker_cannot_create_owner_property(): void
    {
        $user = User::factory()->create(['role' => 'seeker']);
        $this->actingAs($user)->postJson('/api/properties', ['name' => 'Secret', 'type' => 'Maison'])->assertForbidden();
    }

    public function test_owner_sees_owned_rental_and_family_properties(): void
    {
        $this->seed();
        $owner = User::where('role', 'owner')->first();
        $this->actingAs($owner)->getJson('/api/properties')
            ->assertOk()
            ->assertJsonCount(4, 'data')
            ->assertJsonFragment(['name' => 'Parcelle Agblangandan', 'is_private' => true]);
    }
}
