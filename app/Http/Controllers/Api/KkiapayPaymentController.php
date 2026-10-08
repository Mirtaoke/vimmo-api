<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreRentKkiapayIntentRequest;
use App\Http\Requests\VerifyKkiapayTransactionRequest;
use App\Models\KkiapayTransaction;
use App\Services\KkiapayPaymentService;
use App\Support\ApiResponse;
use Illuminate\Http\Request;

class KkiapayPaymentController extends Controller
{
    public function __construct(private readonly KkiapayPaymentService $payments) {}

    public function storeRentIntent(StoreRentKkiapayIntentRequest $request)
    {
        $data = $request->validated();
        $transaction = $this->payments->createRentIntent(
            $request->user(),
            (int) $data['lease_contract_id'],
            array_map('intval', $data['schedule_ids']),
        );

        return ApiResponse::success([
            'payment' => $this->payments->resource($transaction),
            'checkout' => $this->payments->checkout($transaction),
        ], 'Paiement KKiaPay prêt.', 201);
    }

    public function verify(VerifyKkiapayTransactionRequest $request, KkiapayTransaction $kkiapayTransaction)
    {
        $transaction = $this->payments->verifyForUser(
            $kkiapayTransaction,
            $request->user(),
            trim((string) $request->validated('transaction_id')),
        );
        $status = $transaction->status === 'pending' ? 202 : 200;

        return ApiResponse::success([
            'transaction' => $transaction,
            'resource' => $this->payments->resource($transaction),
        ], $status === 202 ? 'Paiement en cours de vérification.' : 'Paiement vérifié par KKiaPay.', $status);
    }

    public function cancel(Request $request, KkiapayTransaction $kkiapayTransaction)
    {
        $transaction = $this->payments->cancelForUser($kkiapayTransaction, $request->user());

        return ApiResponse::success($transaction, 'Paiement annulé.');
    }

    public function webhook(Request $request)
    {
        $secret = (string) config('services.kkiapay.webhook_secret');
        abort_if($secret === '', 503, 'Le secret du webhook KKiaPay n’est pas configuré.');
        $providedSecret = (string) $request->header('x-kkiapay-secret');
        abort_unless($providedSecret !== '' && hash_equals($secret, $providedSecret), 401, 'Signature KKiaPay invalide.');

        $payload = $request->validate([
            'transactionId' => ['required', 'string', 'max:255'],
            'isPaymentSucces' => ['required', 'boolean'],
            'amount' => ['required', 'numeric', 'min:0'],
            'partnerId' => ['nullable', 'string', 'max:255'],
            'event' => ['required', 'in:transaction.success,transaction.failed'],
            'method' => ['nullable', 'string', 'max:50'],
            'failureCode' => ['nullable', 'string', 'max:255'],
            'failureMessage' => ['nullable', 'string', 'max:1000'],
            'performedAt' => ['nullable', 'date'],
            'stateData' => ['nullable', 'array'],
        ]);
        $transaction = $this->payments->handleWebhook($payload);

        return ApiResponse::success($transaction, $transaction === null ? 'Webhook ignoré.' : 'Webhook KKiaPay traité.');
    }
}
