<?php

namespace App\Services;

use App\Models\Payment;
use App\Models\Receipt;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class PaymentService
{
    public function confirm(Payment $payment, int $ownerId): Payment
    {
        return DB::transaction(function () use ($payment, $ownerId) {
            $payment->refresh();
            if ($payment->status === 'confirmed') {
                return $payment;
            }
            abort_unless($payment->status === 'pending', 422, 'Seul un paiement en attente peut être confirmé.');
            $payment->update(['status' => 'confirmed', 'confirmed_by' => $ownerId, 'confirmed_at' => now()]);
            foreach ($payment->schedules as $schedule) {
                $paid = (float) $schedule->paid_amount + (float) $schedule->pivot->amount;
                $schedule->update(['paid_amount' => $paid, 'status' => $paid >= (float) $schedule->amount ? 'paid' : 'partial']);
            }
            Receipt::firstOrCreate(['payment_id' => $payment->id], ['reference' => 'QTT-'.now()->format('Y').'-'.str_pad((string) $payment->id, 6, '0', STR_PAD_LEFT), 'verification_token' => (string) Str::uuid(), 'generated_at' => now()]);
            DB::table('notifications')->insert(['user_id' => $payment->contract->tenant_id, 'type' => 'payment', 'title' => 'Paiement confirmé', 'body' => 'Votre paiement '.$payment->reference.' a été confirmé. Votre quittance est disponible.', 'data' => json_encode(['payment_id' => $payment->id]), 'created_at' => now(), 'updated_at' => now()]);

            return $payment->fresh(['schedules', 'receipt']);
        });
    }
}
