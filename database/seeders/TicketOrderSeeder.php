<?php

namespace Database\Seeders;

use App\Models\Event;
use App\Models\Ticket;
use App\Models\TicketOrder;
use App\Models\TicketType;
use App\Models\User;
use Illuminate\Database\Seeder;

class TicketOrderSeeder extends Seeder
{
    public function run(): void
    {
        $e = Event::firstOrFail();
        $type = TicketType::where('event_id', $e->id)->firstOrFail();
        $buyer = User::where('role', 'seeker')->firstOrFail();
        $order = TicketOrder::updateOrCreate(['reference' => 'ORD-DEMO-2026-001'], ['buyer_id' => $buyer->id, 'event_id' => $e->id, 'total' => $type->price * 2, 'payment_method' => 'mtn_momo', 'status' => 'paid']);
        for ($n = 1; $n <= 2; $n++) {
            Ticket::updateOrCreate(['code' => 'VIMMO-DEMO-'.$n], ['ticket_order_id' => $order->id, 'ticket_type_id' => $type->id, 'status' => 'valid']);
        }$type->update(['sold' => max((int) $type->sold, 2)]);
    }
}
