<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Payment extends Model
{
    protected $guarded = [];

    protected function casts(): array
    {
        return ['amount' => 'decimal:2', 'paid_at' => 'datetime', 'confirmed_at' => 'datetime'];
    }

    public function contract()
    {
        return $this->belongsTo(LeaseContract::class, 'lease_contract_id');
    }

    public function schedules()
    {
        return $this->belongsToMany(RentSchedule::class, 'payment_schedule')->withPivot('amount');
    }

    public function receipt()
    {
        return $this->hasOne(Receipt::class);
    }
}
