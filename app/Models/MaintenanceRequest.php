<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MaintenanceRequest extends Model
{
    protected $guarded = [];

    protected function casts(): array
    {
        return ['scheduled_at' => 'datetime'];
    }

    public function unit()
    {
        return $this->belongsTo(Unit::class);
    }

    public function reporter()
    {
        return $this->belongsTo(User::class, 'reported_by');
    }

    public function media()
    {
        return $this->morphMany(Media::class, 'mediable');
    }

    public function comments()
    {
        return $this->hasMany(MaintenanceComment::class);
    }
}
