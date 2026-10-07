<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Unit extends Model
{
    protected $guarded = [];

    protected function casts(): array
    {
        return [
            'amenities' => 'array',
            'amenity_details' => 'array',
            'surface' => 'decimal:2',
            'monthly_rent' => 'decimal:2',
            'monthly_charges' => 'decimal:2',
            'deposit_amount' => 'decimal:2',
            'advance_months' => 'integer',
        ];
    }

    public function property()
    {
        return $this->belongsTo(Property::class);
    }

    public function listings()
    {
        return $this->hasMany(Listing::class);
    }

    public function contracts()
    {
        return $this->hasMany(LeaseContract::class);
    }

    public function media()
    {
        return $this->morphMany(Media::class, 'mediable');
    }
}
