<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RentalApplication extends Model
{
    protected $guarded = [];

    protected function casts(): array
    {
        return ['profile_data' => 'array'];
    }

    public function listing()
    {
        return $this->belongsTo(Listing::class);
    }

    public function applicant()
    {
        return $this->belongsTo(User::class, 'applicant_id');
    }
}
