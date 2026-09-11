<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LeaseContract extends Model
{
    protected $guarded = [];

    protected function casts(): array
    {
        return ['starts_at' => 'date', 'ends_at' => 'date', 'rent_amount' => 'decimal:2'];
    }

    public function unit()
    {
        return $this->belongsTo(Unit::class);
    }

    public function owner()
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    public function tenant()
    {
        return $this->belongsTo(User::class, 'tenant_id');
    }

    public function schedules()
    {
        return $this->hasMany(RentSchedule::class);
    }

    public function payments()
    {
        return $this->hasMany(Payment::class);
    }

    public function inspections()
    {
        return $this->hasMany(Inspection::class);
    }

    public function media()
    {
        return $this->morphMany(Media::class, 'mediable');
    }
}
