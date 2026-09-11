<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_registration_stays_pending_until_otp_is_verified(): void
    {
        $this->postJson('/api/auth/register', ['first_name' => 'Nadia', 'last_name' => 'Kiki', 'email' => 'nadia@example.com', 'phone' => '97001122', 'role' => 'seeker', 'password' => 'password', 'password_confirmation' => 'password'])
            ->assertCreated()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['email', 'sandbox_otp']])
            ->assertJsonMissingPath('data.token')
            ->assertJsonMissingPath('data.user');

        $this->assertDatabaseMissing('users', ['email' => 'nadia@example.com']);
        $this->assertDatabaseHas('pending_registrations', ['email' => 'nadia@example.com']);
    }

    public function test_public_can_list_published_listings(): void
    {
        $this->seed();
        $this->getJson('/api/listings')->assertOk()->assertJsonPath('success', true)->assertJsonCount(12, 'data.data');
    }

    public function test_registered_user_can_verify_the_random_otp(): void
    {
        $response = $this->postJson('/api/auth/register', ['first_name' => 'Awa', 'last_name' => 'Dossou', 'email' => 'awa@example.com', 'phone' => '97003344', 'role' => 'seeker', 'password' => 'password', 'password_confirmation' => 'password'])->assertCreated();
        $otp = $response->json('data.sandbox_otp');
        $this->assertDatabaseMissing('users', ['email' => 'awa@example.com']);
        $this->postJson('/api/auth/verify-otp', ['email' => 'awa@example.com', 'code' => $otp])->assertOk()->assertJsonPath('success', true);
        $this->assertNotNull(User::where('email', 'awa@example.com')->first()->phone_verified_at);
        $this->assertDatabaseMissing('pending_registrations', ['email' => 'awa@example.com']);
    }

    public function test_pending_registration_can_be_submitted_again_without_unique_error(): void
    {
        $payload = ['first_name' => 'Awa', 'last_name' => 'Dossou', 'email' => 'pending@example.com', 'phone' => '97005566', 'role' => 'seeker', 'password' => 'password', 'password_confirmation' => 'password'];

        $this->postJson('/api/auth/register', $payload)->assertCreated();
        $this->postJson('/api/auth/register', $payload)->assertCreated()->assertJsonPath('success', true);

        $this->assertDatabaseCount('pending_registrations', 1);
        $this->assertDatabaseMissing('users', ['email' => 'pending@example.com']);
    }

    public function test_tenant_cannot_create_an_account_from_public_registration(): void
    {
        $this->postJson('/api/auth/register', ['first_name' => 'Lina', 'last_name' => 'Kora', 'email' => 'lina@example.com', 'phone' => '97007788', 'role' => 'tenant', 'password' => 'password', 'password_confirmation' => 'password'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('role');

        $this->assertDatabaseMissing('users', ['email' => 'lina@example.com']);
        $this->assertDatabaseMissing('pending_registrations', ['email' => 'lina@example.com']);
    }

    public function test_user_can_reset_password_with_emailed_otp(): void
    {
        $this->seed();
        $response = $this->postJson('/api/auth/forgot-password', [
            'email' => 'proprietaire@vimmo.bj',
        ])->assertOk()->assertJsonPath('success', true);

        $otp = $response->json('data.sandbox_otp');
        $this->assertMatchesRegularExpression('/^\d{6}$/', $otp);

        $this->postJson('/api/auth/reset-password', [
            'email' => 'proprietaire@vimmo.bj',
            'code' => $otp,
            'password' => 'nouveau-password',
            'password_confirmation' => 'nouveau-password',
        ])->assertOk()->assertJsonPath('success', true);

        $this->postJson('/api/auth/login', [
            'identifier' => 'proprietaire@vimmo.bj',
            'password' => 'nouveau-password',
        ])->assertOk();
    }
}
