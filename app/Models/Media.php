<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\URL;

class Media extends Model
{
    protected $guarded = [];

    protected $appends = ['view_url'];

    protected function casts(): array
    {
        return ['metadata' => 'array'];
    }

    public function mediable()
    {
        return $this->morphTo();
    }

    public function getViewUrlAttribute(): ?string
    {
        if (
            $this->disk !== 'public' ||
            ! in_array($this->collection, ['gallery', 'photos'], true) ||
            ! str_starts_with((string) $this->mime_type, 'image/')
        ) {
            return null;
        }

        return URL::temporarySignedRoute(
            'media.view',
            now()->addDays(30),
            ['media' => $this->getKey()],
            absolute: false,
        );
    }
}
