<?php

namespace App\Services;

use App\Models\KkiapayTransaction;
use App\Models\LeaseContract;
use App\Models\Payment;
use App\Models\RentSchedule;
use App\Models\TicketPayment;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class KkiapayPaymentService
{
    public function __construct(
        private readonly KkiapayGateway $gateway,
        private readonly PaymentService $rentPayments,
        private readonly TicketPaymentService $ticketPayments,
    ) {}

    /** @param list<int> $scheduleIds */
    public function createRentIntent(User $tenant, int $contractId, array $scheduleIds): KkiapayTransaction
    {
        $this->ensureConfigured();

        return DB::transaction(function () use ($tenant, $contractId, $scheduleIds): KkiapayTransaction {
            $contract = LeaseContract::query()->lockForUpdate()->findOrFail($contractId);
            abort_unless($contract->tenant_id === $tenant->id, 404);

            $schedules = RentSchedule::query()
                ->where('lease_contract_id', $contract->id)
                ->whereIn('id', $scheduleIds)
                ->orderBy('due_date')
                ->lockForUpdate()
                ->get();
            abort_unless($schedules->count() === count($scheduleIds), 422, 'Certaines échéances ne correspondent pas à ce contrat.');

            $alreadyPending = Payment::query()
                ->where('lease_contract_id', $contract->id)
                ->where('payer_id', $tenant->id)
                ->where('status', 'pending')
                ->whereHas('schedules', fn ($query) => $query->whereIn('rent_schedules.id', $scheduleIds))
                ->whereHas('kkiapayTransaction', fn ($query) => $query->whereIn('status', ['initiated', 'pending']))
                ->exists();
            abort_if($alreadyPending, 422, 'Un paiement KKiaPay est déjà en cours pour cette échéance.');

            $amount = $schedules->sum(
                fn (RentSchedule $schedule): float => max(0, (float) $schedule->amount - (float) $schedule->paid_amount),
            );
            abort_if($amount <= 0, 422, 'Ces échéances sont déjà réglées.');

            $payment = Payment::query()->create([
                'lease_contract_id' => $contract->id,
                'payer_id' => $tenant->id,
                'reference' => 'PAY-'.now()->format('Ymd').'-'.Str::upper(Str::random(6)),
                'amount' => $amount,
                'method' => 'other',
                'status' => 'pending',
                'paid_at' => now(),
                'note' => 'Paiement en ligne initié avec KKiaPay.',
            ]);

            foreach ($schedules as $schedule) {
                $balance = max(0, (float) $schedule->amount - (float) $schedule->paid_amount);
                if ($balance > 0) {
                    $payment->schedules()->attach($schedule->id, ['amount' => $balance]);
                }
            }

            return $this->createIntent($payment, $tenant, $amount);
        });
    }

    public function createIntent(Model $payable, User $user, float $amount): KkiapayTransaction
    {
        $this->ensureConfigured();
        abort_if($amount <= 0, 422, 'Le montant du paiement doit être supérieur à zéro.');

        return $payable->morphOne(KkiapayTransaction::class, 'payable')->create([
            'user_id' => $user->id,
            'partner_id' => (string) Str::uuid(),
            'amount' => $amount,
            'currency' => 'XOF',
            'status' => 'initiated',
        ]);
    }

    /** @return array<string, mixed> */
    public function checkout(KkiapayTransaction $transaction): array
    {
        $transaction->loadMissing('user:id,name,email,phone');

        return [
            'id' => $transaction->id,
            'amount' => (int) round((float) $transaction->amount),
            'currency' => $transaction->currency,
            'partner_id' => $transaction->partner_id,
            'public_key' => (string) config('services.kkiapay.public_key'),
            'sandbox' => (bool) config('services.kkiapay.sandbox'),
            'theme' => (string) config('services.kkiapay.theme'),
            'countries' => config('services.kkiapay.countries'),
            'payment_methods' => config('services.kkiapay.payment_methods'),
            'callback_url' => config('services.kkiapay.callback_url'),
            'customer' => [
                'name' => $transaction->user->name,
                'email' => $transaction->user->email,
                'phone' => $transaction->user->phone,
            ],
        ];
    }

    public function verifyForUser(KkiapayTransaction $transaction, User $user, string $providerTransactionId): KkiapayTransaction
    {
        abort_unless($transaction->user_id === $user->id, 404);

        if ($transaction->status === 'paid') {
            abort_unless($transaction->provider_transaction_id === $providerTransactionId, 409, 'Cette intention a déjà été réglée avec une autre transaction.');

            return $transaction;
        }

        abort_unless(in_array($transaction->status, ['initiated', 'pending'], true), 422, 'Cette intention de paiement n’est plus active.');
        $payload = $this->gateway->verifyTransaction($providerTransactionId);

        return $this->applyProviderPayload($transaction, $payload, $providerTransactionId);
    }

    public function cancelForUser(KkiapayTransaction $transaction, User $user): KkiapayTransaction
    {
        abort_unless($transaction->user_id === $user->id, 404);

        return DB::transaction(function () use ($transaction): KkiapayTransaction {
            $locked = KkiapayTransaction::query()->lockForUpdate()->findOrFail($transaction->id);
            if (! in_array($locked->status, ['initiated', 'pending'], true)) {
                return $locked;
            }

            $locked->update(['status' => 'cancelled', 'failed_at' => now()]);
            $this->failPayable($locked, 'Paiement annulé par l’utilisateur.');

            return $locked->fresh();
        });
    }

    /** @param array<string, mixed> $payload */
    public function handleWebhook(array $payload): ?KkiapayTransaction
    {
        $providerTransactionId = trim((string) ($payload['transactionId'] ?? ''));
        $partnerId = trim((string) ($payload['partnerId'] ?? ''));
        $transaction = KkiapayTransaction::query()
            ->when($partnerId !== '', fn ($query) => $query->where('partner_id', $partnerId))
            ->when(
                $partnerId === '' && $providerTransactionId !== '',
                fn ($query) => $query->where('provider_transaction_id', $providerTransactionId),
            )
            ->first();

        if ($transaction === null) {
            return null;
        }

        return $this->applyProviderPayload($transaction, $payload, $providerTransactionId);
    }

    /** @return array<string, mixed>|Model */
    public function resource(KkiapayTransaction $transaction): array|Model
    {
        $payable = $transaction->payable()->firstOrFail();
        if ($payable instanceof Payment) {
            return $payable->fresh([
                'contract.unit.property',
                'schedules',
                'receipt',
                'kkiapayTransaction',
            ]);
        }

        if ($payable instanceof TicketPayment) {
            return $payable->order()->with([
                'payment.kkiapayTransaction',
                'tickets.ticketType',
                'event',
            ])->firstOrFail();
        }

        return $payable;
    }

    /** @param array<string, mixed> $rawPayload */
    private function applyProviderPayload(KkiapayTransaction $transaction, array $rawPayload, string $providerTransactionId): KkiapayTransaction
    {
        $payload = isset($rawPayload['data']) && is_array($rawPayload['data'])
            ? $rawPayload['data']
            : $rawPayload;
        $verifiedTransactionId = trim((string) ($payload['transactionId'] ?? $providerTransactionId));
        abort_if($verifiedTransactionId === '', 422, 'KKiaPay n’a fourni aucune référence de transaction.');
        abort_if($providerTransactionId !== '' && $verifiedTransactionId !== $providerTransactionId, 422, 'La référence vérifiée ne correspond pas au paiement.');

        $status = Str::upper((string) ($payload['status'] ?? ''));
        $successful = ($payload['isPaymentSucces'] ?? false) === true
            || in_array($status, ['SUCCESS', 'PAID', 'COMPLETE', 'COMPLETED'], true);
        $pending = in_array($status, ['PENDING', 'INITIATED', 'PROCESSING'], true);

        if ($pending && ! $successful) {
            $transaction->update([
                'provider_transaction_id' => $verifiedTransactionId,
                'status' => 'pending',
                'provider_payload' => $payload,
            ]);

            return $transaction->fresh();
        }

        if (! $successful) {
            $message = (string) ($payload['failureMessage'] ?? 'Le paiement a été refusé par KKiaPay.');
            $this->markFailed($transaction, $payload, $verifiedTransactionId, $message);
            throw ValidationException::withMessages(['transaction_id' => [$message]]);
        }

        $verifiedAmount = (float) ($payload['amount'] ?? -1);
        abort_if(abs($verifiedAmount - (float) $transaction->amount) > 0.001, 422, 'Le montant confirmé par KKiaPay ne correspond pas au montant attendu.');
        $verifiedPartnerId = trim((string) ($payload['partnerId'] ?? $payload['externalTransactionId'] ?? ''));
        abort_if($verifiedPartnerId !== '' && $verifiedPartnerId !== $transaction->partner_id, 422, 'La transaction KKiaPay ne correspond pas à cette intention.');

        return DB::transaction(function () use ($transaction, $payload, $verifiedTransactionId): KkiapayTransaction {
            $locked = KkiapayTransaction::query()->lockForUpdate()->findOrFail($transaction->id);
            if ($locked->status === 'paid') {
                abort_unless($locked->provider_transaction_id === $verifiedTransactionId, 409, 'Cette intention est déjà réglée.');

                return $locked;
            }

            $duplicate = KkiapayTransaction::query()
                ->where('provider_transaction_id', $verifiedTransactionId)
                ->whereKeyNot($locked->id)
                ->exists();
            abort_if($duplicate, 409, 'Cette transaction KKiaPay a déjà été utilisée.');

            $locked->update([
                'provider_transaction_id' => $verifiedTransactionId,
                'status' => 'paid',
                'provider_payload' => $payload,
                'verified_at' => now(),
                'failed_at' => null,
                'failure_code' => null,
                'failure_message' => null,
            ]);
            $this->confirmPayable($locked, $verifiedTransactionId);

            return $locked->fresh();
        });
    }

    /** @param array<string, mixed> $payload */
    private function markFailed(KkiapayTransaction $transaction, array $payload, string $providerTransactionId, string $message): void
    {
        DB::transaction(function () use ($transaction, $payload, $providerTransactionId, $message): void {
            $locked = KkiapayTransaction::query()->lockForUpdate()->findOrFail($transaction->id);
            if ($locked->status === 'paid') {
                return;
            }
            $locked->update([
                'provider_transaction_id' => $providerTransactionId !== '' ? $providerTransactionId : null,
                'status' => 'failed',
                'provider_payload' => $payload,
                'failure_code' => $payload['failureCode'] ?? null,
                'failure_message' => $message,
                'failed_at' => now(),
            ]);
            $this->failPayable($locked, $message);
        });
    }

    private function confirmPayable(KkiapayTransaction $transaction, string $providerTransactionId): void
    {
        $payable = $transaction->payable()->firstOrFail();
        if ($payable instanceof Payment) {
            $this->rentPayments->confirm($payable, null);

            return;
        }
        if ($payable instanceof TicketPayment) {
            $this->ticketPayments->confirm($payable, $providerTransactionId);
        }
    }

    private function failPayable(KkiapayTransaction $transaction, string $message): void
    {
        $payable = $transaction->payable()->firstOrFail();
        if ($payable instanceof Payment && $payable->status === 'pending') {
            $payable->update([
                'status' => 'rejected',
                'confirmed_at' => now(),
                'note' => trim(($payable->note ? $payable->note."\n" : '').$message),
            ]);

            return;
        }
        if ($payable instanceof TicketPayment) {
            $this->ticketPayments->fail($payable, $transaction->provider_transaction_id);
        }
    }

    private function ensureConfigured(): void
    {
        abort_unless($this->gateway->isConfigured(), 503, 'Le paiement KKiaPay n’est pas encore configuré sur le serveur.');
    }
}
