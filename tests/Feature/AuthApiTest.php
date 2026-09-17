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
            ->assertJsonPath('data.expires_in', 600)
            ->assertJsonPath('data.resend_available_in', 60)
            ->assertJsonPath('data.remaining_resends', 5)
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

    public function test_otp_resend_has_a_cooldown_and_a_maximum(): void
    {
        $payload = ['first_name' => 'Mina', 'last_name' => 'Kora', 'email' => 'mina@example.com', 'phone' => '97006677', 'role' => 'seeker', 'password' => 'password', 'password_confirmation' => 'password'];
        $this->postJson('/api/auth/register', $payload)->assertCreated();

        $this->postJson('/api/auth/resend-otp', ['email' => 'mina@example.com'])
            ->assertTooManyRequests()
            ->assertJsonPath('errors.remaining_resends', 5);

        $this->travel(61)->seconds();
        $this->postJson('/api/auth/resend-otp', ['email' => 'mina@example.com'])
            ->assertOk()
            ->assertJsonPath('data.expires_in', 600)
            ->assertJsonPath('data.remaining_resends', 4);

        \Illuminate\Support\Facades\DB::table('pending_registrations')
            ->where('email', 'mina@example.com')
            ->update(['resend_count' => 5, 'last_sent_at' => now()->subMinutes(2)]);
        $this->travel(61)->seconds();
        $this->postJson('/api/auth/resend-otp', ['email' => 'mina@example.com'])
            ->assertTooManyRequests()
            ->assertJsonPath('errors.remaining_resends', 0);
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
        ])->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.expires_in', 600)
            ->assertJsonPath('data.resend_available_in', 60)
            ->assertJsonPath('data.remaining_resends', 5);

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

    public function test_password_reset_otp_resend_has_cooldown_and_limit(): void
    {
        $this->seed();
        $email = 'proprietaire@vimmo.bj';
        $this->postJson('/api/auth/forgot-password', ['email' => $email])->assertOk();

        $this->postJson('/api/auth/forgot-password', ['email' => $email, 'resend' => true])
            ->assertTooManyRequests()
            ->assertJsonPath('errors.remaining_resends', 5);

        $this->travel(61)->seconds();
        $this->postJson('/api/auth/forgot-password', ['email' => $email, 'resend' => true])
            ->assertOk()
            ->assertJsonPath('data.remaining_resends', 4);

        \Illuminate\Support\Facades\DB::table('otp_codes')
            ->where('purpose', 'password_reset')
            ->whereNull('used_at')
            ->update(['resend_count' => 5, 'last_sent_at' => now()->subMinutes(2)]);
        $this->travel(61)->seconds();
        $this->postJson('/api/auth/forgot-password', ['email' => $email, 'resend' => true])
            ->assertTooManyRequests()
            ->assertJsonPath('errors.remaining_resends', 0);
    }
}
