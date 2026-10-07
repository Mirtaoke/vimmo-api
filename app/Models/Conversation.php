<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Conversation extends Model
{
    protected $guarded = [];

    public function participants()
    {
        return $this->belongsToMany(User::class, 'conversation_participants')->withPivot('last_read_at');
    }

    public function messages()
    {
        return $this->hasMany(Message::class);
    }

    public function latestMessage(): HasOne
    {
        return $this->hasOne(Message::class)->latestOfMany();
    }

    public function unit()
    {
        return $this->belongsTo(Unit::class);
    }
}
