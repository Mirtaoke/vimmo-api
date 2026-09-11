<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RentSchedule extends Model
{
    protected $guarded = [];

    protected function casts(): array
    {
        return ['period_start' => 'date', 'period_end' => 'date', 'due_date' => 'date', 'amount' => 'decimal:2', 'paid_amount' => 'decimal:2'];
    }

    public function contract()
    {
        return $this->belongsTo(LeaseContract::class, 'lease_contract_id');
    }
}
