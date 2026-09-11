<?php

namespace Database\Seeders;

use App\Models\TicketOrder;
use App\Models\TicketPayment;
use Illuminate\Database\Seeder;

class TicketPaymentSeeder extends Seeder
{
    public function run(): void
    {
        foreach (TicketOrder::where('status', 'paid')->get() as $order) {
            TicketPayment::updateOrCreate(['ticket_order_id' => $order->id], ['reference' => 'TPAY-'.str_pad((string) $order->id, 8, '0', STR_PAD_LEFT), 'provider' => $order->payment_method, 'provider_reference' => 'DEMO-'.$order->reference, 'amount' => $order->total, 'currency' => 'XOF', 'status' => 'paid', 'paid_at' => $order->created_at]);
        }
    }
}
