<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Ticket extends Model
{
    protected $guarded = [];

    protected function casts(): array
    {
        return ['scanned_at' => 'datetime'];
    }

    public function order()
    {
        return $this->belongsTo(TicketOrder::class, 'ticket_order_id');
    }

    public function ticketType()
    {
        return $this->belongsTo(TicketType::class);
    }
}
