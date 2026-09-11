<?php

namespace Database\Seeders;

use App\Models\Listing;
use App\Models\Unit;
use Illuminate\Database\Seeder;

class ListingSeeder extends Seeder
{
    public function run(): void
    {
        foreach (Unit::with('property')->whereHas('property', fn ($query) => $query->where('is_private', false))->get() as $unit) {
            Listing::updateOrCreate(
                ['unit_id' => $unit->id],
                ['owner_id' => $unit->property->owner_id, 'title' => $unit->property->name, 'description' => 'Découvrez '.$unit->property->name.', un bien lumineux situé à '.$unit->property->district.' avec des équipements modernes et un environnement sécurisé.', 'price' => $unit->monthly_rent, 'deposit' => $unit->monthly_rent * 2, 'charges' => 25000, 'available_from' => now()->addDays(($unit->id % 20) + 1)->toDateString(), 'status' => 'published', 'is_verified' => true, 'published_at' => now()->subDays($unit->id % 12)],
            );
        }
    }
}
