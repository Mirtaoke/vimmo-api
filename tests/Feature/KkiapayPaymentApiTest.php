<?php

namespace Tests\Feature;

use App\Models\LeaseContract;
use App\Models\Payment;
use App\Models\RentSchedule;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class KkiapayPaymentApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        config([
            'services.kkiapay.public_key' => 'public-test',
            'services.kkiapay.private_key' => 'private-test',
            'services.kkiapay.secret' => 'secret-test',
            'services.kkiapay.webhook_secret' => 'webhook-test',
            'services.kkiapay.sandbox' => true,
            'services.kkiapay.base_url' => 'https://api-sandbox.kkiapay.me',
        ]);
    }

    public function test_tenant_payment_is_confirmed_only_after_server_verification(): void
    {
        Storage::fake('private');
        [$tenant, , , $checkout, $payment] = $this->createRentIntent();

        Http::preventStrayRequests();
        Http::fake([
            'https://api-sandbox.kkiapay.me/api/v1/transactions/status' => Http::response([
                'status' => 'SUCCESS',
                'isPaymentSucces' => true,
                'transactionId' => 'KKP-RENT-SUCCESS',
                'amount' => $checkout['amount'],
                'partnerId' => $checkout['partner_id'],
                'method' => 'MOBILE_MONEY',
            ]),
        ]);

        $this->actingAs($tenant)
            ->postJson('/api/kkiapay/transactions/'.$checkout['id'].'/verify', [
                'transaction_id' => 'KKP-RENT-SUCCESS',
            ])
            ->assertOk()
            ->assertJsonPath('data.transaction.status', 'paid')
            ->assertJsonPath('data.resource.status', 'confirmed');

        $this->assertDatabaseHas('kkiapay_transactions', [
            'id' => $checkout['id'],
            'provider_transaction_id' => 'KKP-RENT-SUCCESS',
            'status' => 'paid',
        ]);
        $this->assertDatabaseHas('payments', ['status' => 'confirmed']);
        $this->assertDatabaseHas('receipts', ['payment_id' => $payment->id]);

        $this->actingAs($tenant)
            ->post('/api/payments/'.$payment->id.'/proof', [
                'proof' => UploadedFile::fake()->image('capture-kkiapay.jpg'),
            ], ['Accept' => 'application/json'])
            ->assertOk()
            ->assertJsonPath('data.id', $payment->id);
        $proofPath = $payment->fresh()->proof_path;
        $this->assertNotNull($proofPath);
        Storage::disk('private')->assertExists($proofPath);

        Http::assertSent(fn ($request): bool => $request->hasHeader('X-API-KEY', 'public-test')
            && $request->hasHeader('X-PRIVATE-KEY', 'private-test')
            && $request->hasHeader('X-SECRET-KEY', 'secret-test')
            && $request['transactionId'] === 'KKP-RENT-SUCCESS');
    }

    public function test_amount_mismatch_never_confirms_a_payment(): void
    {
        [$tenant, , , $checkout, $payment] = $this->createRentIntent();

        Http::fake([
            'https://api-sandbox.kkiapay.me/api/v1/transactions/status' => Http::response([
                'status' => 'SUCCESS',
                'isPaymentSucces' => true,
                'transactionId' => 'KKP-WRONG-AMOUNT',
                'amount' => $checkout['amount'] - 1,
                'partnerId' => $checkout['partner_id'],
            ]),
        ]);

        $this->actingAs($tenant)
            ->postJson('/api/kkiapay/transactions/'.$checkout['id'].'/verify', [
                'transaction_id' => 'KKP-WRONG-AMOUNT',
            ])
            ->assertUnprocessable();

        $this->assertDatabaseHas('kkiapay_transactions', [
            'id' => $checkout['id'],
            'status' => 'initiated',
        ]);
        $this->assertDatabaseHas('payments', ['status' => 'pending']);
        $this->assertDatabaseMissing('receipts', ['payment_id' => $payment->id]);
    }

    public function test_pending_provider_response_keeps_the_payment_pending(): void
    {
        [$tenant, , , $checkout, $payment] = $this->createRentIntent();

        Http::fake([
            'https://api-sandbox.kkiapay.me/api/v1/transactions/status' => Http::response([
                'status' => 'PENDING',
                'isPaymentSucces' => false,
                'transactionId' => 'KKP-STILL-PENDING',
                'amount' => $checkout['amount'],
                'partnerId' => $checkout['partner_id'],
            ]),
        ]);

        $this->actingAs($tenant)
            ->postJson('/api/kkiapay/transactions/'.$checkout['id'].'/verify', [
                'transaction_id' => 'KKP-STILL-PENDING',
            ])
            ->assertStatus(202)
            ->assertJsonPath('data.transaction.status', 'pending')
            ->assertJsonPath('data.resource.status', 'pending');

        $this->assertDatabaseMissing('receipts', ['payment_id' => $payment->id]);
    }

    public function test_failed_kkiapay_attempt_is_hidden_from_history_and_dashboard(): void
    {
        [$tenant, , , $checkout, $payment] = $this->createRentIntent();

        Http::fake([
            'https://api-sandbox.kkiapay.me/api/v1/transactions/status' => Http::response([
                'status' => 'FAILED',
                'isPaymentSucces' => false,
                'transactionId' => 'KKP-FAILED',
                'amount' => $checkout['amount'],
                'partnerId' => $checkout['partner_id'],
                'failureMessage' => 'Paiement refusé.',
            ]),
        ]);

        $this->actingAs($tenant)
            ->postJson('/api/kkiapay/transactions/'.$checkout['id'].'/verify', [
                'transaction_id' => 'KKP-FAILED',
            ])
            ->assertUnprocessable();

        $this->assertDatabaseHas('payments', [
            'id' => $payment->id,
            'status' => 'rejected',
        ]);
        $this->actingAs($tenant)
            ->getJson('/api/payments')
            ->assertOk()
            ->assertJsonMissing(['id' => $payment->id]);
        $visibleCount = Payment::query()
            ->visibleToUsers()
            ->where('lease_contract_id', $payment->lease_contract_id)
            ->count();
        $this->actingAs($tenant)
            ->getJson('/api/dashboard')
            ->assertOk()
            ->assertJsonPath('data.payments', $visibleCount);
    }

    public function test_a_user_cannot_verify_another_users_payment(): void
    {
        [, , , $checkout] = $this->createRentIntent();
        $otherUser = User::factory()->create(['role' => 'seeker']);
        Http::preventStrayRequests();

        $this->actingAs($otherUser)
            ->postJson('/api/kkiapay/transactions/'.$checkout['id'].'/verify', [
                'transaction_id' => 'KKP-FORBIDDEN',
            ])
            ->assertNotFound();

        Http::assertNothingSent();
        $this->assertDatabaseHas('kkiapay_transactions', [
            'id' => $checkout['id'],
            'status' => 'initiated',
        ]);
    }

    public function test_signed_webhook_is_idempotent_and_invalid_secret_is_rejected(): void
    {
        [, , , $checkout, $payment] = $this->createRentIntent();
        $payload = [
            'transactionId' => 'KKP-WEBHOOK-SUCCESS',
            'isPaymentSucces' => true,
            'amount' => $checkout['amount'],
            'partnerId' => $checkout['partner_id'],
            'event' => 'transaction.success',
            'method' => 'MOBILE_MONEY',
        ];

        $this->postJson('/api/kkiapay/webhook', $payload, ['x-kkiapay-secret' => 'wrong-secret'])
            ->assertUnauthorized();
        $this->assertDatabaseHas('kkiapay_transactions', [
            'id' => $checkout['id'],
            'status' => 'initiated',
        ]);

        $headers = ['x-kkiapay-secret' => 'webhook-test'];
        $this->postJson('/api/kkiapay/webhook', $payload, $headers)
            ->assertOk()
            ->assertJsonPath('data.status', 'paid');
        $this->postJson('/api/kkiapay/webhook', $payload, $headers)
            ->assertOk()
            ->assertJsonPath('data.status', 'paid');

        $this->assertSame(1, $payment->receipt()->count());
        $this->assertDatabaseHas('payments', ['status' => 'confirmed']);
    }

    /** @return array{User, LeaseContract, RentSchedule, array<string, mixed>, Payment} */
    private function createRentIntent(): array
    {
        $this->seed();
        $tenant = User::query()->where('role', 'tenant')->firstOrFail();
        $contract = LeaseContract::query()->where('tenant_id', $tenant->id)->firstOrFail();
        $schedule = RentSchedule::query()
            ->where('lease_contract_id', $contract->id)
            ->where('status', 'upcoming')
            ->firstOrFail();

        $response = $this->actingAs($tenant)->postJson('/api/payments/kkiapay/intents', [
            'lease_contract_id' => $contract->id,
            'schedule_ids' => [$schedule->id],
        ])->assertCreated()
            ->assertJsonPath('data.payment.status', 'pending')
            ->assertJsonPath('data.checkout.public_key', 'public-test')
            ->assertJsonMissingPath('data.checkout.private_key')
            ->assertJsonMissingPath('data.checkout.secret');

        $payment = Payment::query()->latest('id')->firstOrFail();

        return [$tenant, $contract, $schedule, $response->json('data.checkout'), $payment];
    }
}
