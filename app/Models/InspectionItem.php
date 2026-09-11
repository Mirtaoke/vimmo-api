<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class InspectionItem extends Model
{
    protected $guarded = [];

    protected function casts(): array
    {
        return ['anomaly' => 'boolean', 'exit_comparison' => 'array'];
    }

    public function inspection()
    {
        return $this->belongsTo(Inspection::class);
    }

    public function media()
    {
        return $this->morphMany(Media::class, 'mediable');
    }
}
