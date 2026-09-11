<?php

namespace Database\Seeders;

use App\Models\Event;
use App\Models\TicketType;
use Illuminate\Database\Seeder;

class TicketTypeSeeder extends Seeder
{
    public function run(): void
    {
        foreach (Event::all() as $event) {
            foreach ([['Standard', 10000, 300], ['VIP', 25000, 120], ['Duo', 18000, 80]] as $ticket) {
                TicketType::updateOrCreate(['event_id' => $event->id, 'type' => $ticket[0]], ['price' => $ticket[1], 'capacity' => $ticket[2]]);
            }
        }
    }
}
