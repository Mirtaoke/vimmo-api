<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Inspection extends Model
{
    protected $guarded = [];

    protected function casts(): array
    {
        return ['inspection_date' => 'date', 'readings' => 'array', 'keys' => 'array', 'equipment' => 'array'];
    }

    public function contract()
    {
        return $this->belongsTo(LeaseContract::class, 'lease_contract_id');
    }

    public function items()
    {
        return $this->hasMany(InspectionItem::class);
    }

    public function validations()
    {
        return $this->hasMany(InspectionValidation::class);
    }

    public function disputes()
    {
        return $this->hasMany(InspectionDispute::class);
    }
}
