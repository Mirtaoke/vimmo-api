<?php

namespace App\Services;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpKernel\Exception\HttpException;

class KkiapayGateway
{
    public function isConfigured(): bool
    {
        return collect([
            config('services.kkiapay.public_key'),
            config('services.kkiapay.private_key'),
            config('services.kkiapay.secret'),
        ])->every(fn (mixed $value): bool => is_string($value) && trim($value) !== '');
    }

    /** @return array<string, mixed> */
    public function verifyTransaction(string $transactionId): array
    {
        if (! $this->isConfigured()) {
            throw new HttpException(503, 'Le paiement KKiaPay n’est pas encore configuré sur le serveur.');
        }

        try {
            $response = Http::baseUrl((string) config('services.kkiapay.base_url'))
                ->acceptJson()
                ->asJson()
                ->withHeaders([
                    'X-API-KEY' => (string) config('services.kkiapay.public_key'),
                    'X-PRIVATE-KEY' => (string) config('services.kkiapay.private_key'),
                    'X-SECRET-KEY' => (string) config('services.kkiapay.secret'),
                ])
                ->connectTimeout(5)
                ->timeout(15)
                ->retry([250, 750], throw: false)
                ->post('/api/v1/transactions/status', [
                    'transactionId' => $transactionId,
                ]);
        } catch (ConnectionException $exception) {
            Log::warning('KKiaPay est inaccessible pendant la vérification.', [
                'transaction_id' => $transactionId,
                'exception' => $exception::class,
            ]);

            throw new HttpException(503, 'KKiaPay est temporairement inaccessible. Réessayez dans un instant.');
        }

        if (! $response->successful()) {
            Log::warning('KKiaPay a refusé une vérification de transaction.', [
                'transaction_id' => $transactionId,
                'http_status' => $response->status(),
            ]);

            throw new HttpException(502, 'KKiaPay n’a pas pu confirmer cette transaction.');
        }

        $payload = $response->json();
        if (! is_array($payload)) {
            throw new HttpException(502, 'KKiaPay a renvoyé une réponse de vérification invalide.');
        }

        return $payload;
    }
}
