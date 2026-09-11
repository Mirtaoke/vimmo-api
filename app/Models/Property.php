<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Property extends Model
{
    protected $guarded = [];

    protected function casts(): array
    {
        return ['is_private' => 'boolean', 'metadata' => 'array', 'surface' => 'decimal:2', 'latitude' => 'decimal:7', 'longitude' => 'decimal:7'];
    }

    public function owner()
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    public function units()
    {
        return $this->hasMany(Unit::class);
    }

    public function media()
    {
        return $this->morphMany(Media::class, 'mediable');
    }
}
