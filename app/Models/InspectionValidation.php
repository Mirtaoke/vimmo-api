<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class InspectionValidation extends Model
{
    public $timestamps = false;

    protected $guarded = [];

    protected function casts(): array
    {
        return ['validated_at' => 'datetime'];
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
