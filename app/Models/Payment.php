<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\MorphOne;

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

    public function kkiapayTransaction(): MorphOne
    {
        return $this->morphOne(KkiapayTransaction::class, 'payable');
    }

    public function scopeVisibleToUsers(Builder $query): void
    {
        $query->whereDoesntHave(
            'kkiapayTransaction',
            fn (Builder $transaction) => $transaction->whereIn('status', ['failed', 'cancelled']),
        );
    }
}
