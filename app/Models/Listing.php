<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Listing extends Model
{
    protected $guarded = [];

    protected function casts(): array
    {
        return ['is_verified' => 'boolean', 'published_at' => 'datetime', 'available_from' => 'date', 'price' => 'decimal:2'];
    }

    public function owner()
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    public function unit()
    {
        return $this->belongsTo(Unit::class);
    }

    public function media()
    {
        return $this->morphMany(Media::class, 'mediable');
    }
}
