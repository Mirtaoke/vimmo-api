<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class InspectionDispute extends Model
{
    protected $guarded = [];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function item()
    {
        return $this->belongsTo(InspectionItem::class, 'inspection_item_id');
    }
}
