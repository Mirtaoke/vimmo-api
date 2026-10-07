<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\URL;

class Event extends Model
{
    protected $guarded = [];

    protected $appends = ['cover_url'];

    protected function casts(): array
    {
        return ['starts_at' => 'datetime', 'ends_at' => 'datetime', 'latitude' => 'decimal:7', 'longitude' => 'decimal:7'];
    }

    public function ticketTypes()
    {
        return $this->hasMany(TicketType::class);
    }

    public function schedules()
    {
        return $this->hasMany(EventSchedule::class);
    }

    public function orders()
    {
        return $this->hasMany(TicketOrder::class);
    }

    public function organizer()
    {
        return $this->belongsTo(User::class, 'organizer_id');
    }

    public function category()
    {
        return $this->belongsTo(EventCategory::class, 'event_category_id');
    }

    public function getCoverUrlAttribute(): ?string
    {
        if (! $this->cover_path) {
            return null;
        }

        return URL::temporarySignedRoute(
            'events.cover',
            now()->addDays(30),
            ['event' => $this->getKey()],
            absolute: false,
        );
    }
}
