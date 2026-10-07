<?php

namespace App\Services;

use App\Models\Ticket;
use App\Models\TicketPayment;
use App\Models\TicketType;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class TicketPaymentService
{
    public function confirm(TicketPayment $payment, ?string $providerReference = null): TicketPayment
    {
        return DB::transaction(function () use ($payment, $providerReference): TicketPayment {
            $payment = TicketPayment::query()->lockForUpdate()->findOrFail($payment->id);
            $order = $payment->order()->with('event')->lockForUpdate()->firstOrFail();

            if ($payment->status === 'paid' && $order->status === 'paid') {
                return $payment->load('order.tickets.ticketType');
            }

            abort_if(in_array($order->status, ['cancelled', 'refunded'], true), 422, 'Cette commande est annulée.');

            $metadata = $payment->metadata ?? [];
            $quantity = max(1, (int) ($metadata['quantity'] ?? 1));
            $ticketTypeId = (int) ($metadata['ticket_type_id'] ?? 0);
            $ticketType = TicketType::query()
                ->where('event_id', $order->event_id)
                ->lockForUpdate()
                ->findOrFail($ticketTypeId);
            $existingTickets = $order->tickets()->count();
            $ticketsToCreate = max(0, $quantity - $existingTickets);

            abort_if(
                $ticketType->sold + $ticketsToCreate > $ticketType->capacity,
                422,
                'La capacité disponible est insuffisante.',
            );

            for ($index = 0; $index < $ticketsToCreate; $index++) {
                Ticket::query()->create([
                    'ticket_order_id' => $order->id,
                    'ticket_type_id' => $ticketType->id,
                    'code' => (string) Str::uuid(),
                ]);
            }

            if ($ticketsToCreate > 0) {
                $ticketType->increment('sold', $ticketsToCreate);
            }

            $payment->update([
                'provider_reference' => $providerReference ?: $payment->provider_reference,
                'status' => 'paid',
                'paid_at' => $payment->paid_at ?? now(),
            ]);
            $order->update(['status' => 'paid']);

            $this->notify(
                $order->buyer_id,
                'ticket_confirmed',
                'Billets confirmés',
                'Votre commande '.$order->reference.' est confirmée.',
                ['order_id' => $order->id, 'event_id' => $order->event_id],
            );
            $this->notify(
                $order->event->organizer_id,
                'ticket_sale',
                'Nouvelle vente',
                $quantity.' billet(s) vendu(s) pour « '.$order->event->title.' ».',
                ['order_id' => $order->id, 'event_id' => $order->event_id],
            );

            return $payment->fresh('order.tickets.ticketType');
        });
    }

    public function fail(TicketPayment $payment, ?string $providerReference = null): TicketPayment
    {
        return DB::transaction(function () use ($payment, $providerReference): TicketPayment {
            $payment = TicketPayment::query()->lockForUpdate()->findOrFail($payment->id);

            if ($payment->status === 'paid') {
                return $payment;
            }

            $payment->update([
                'provider_reference' => $providerReference ?: $payment->provider_reference,
                'status' => 'failed',
            ]);
            $payment->order()->update(['status' => 'cancelled']);

            return $payment->fresh('order');
        });
    }

    private function notify(int $userId, string $type, string $title, string $body, array $data): void
    {
        DB::table('notifications')->insert([
            'user_id' => $userId,
            'type' => $type,
            'title' => $title,
            'body' => $body,
            'data' => json_encode($data, JSON_THROW_ON_ERROR),
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }
}
