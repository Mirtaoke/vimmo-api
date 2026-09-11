<?php

namespace Database\Seeders;

use App\Models\Listing;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class MarketplaceActivitySeeder extends Seeder
{
    public function run(): void
    {
        $u = User::where('role', 'seeker')->firstOrFail();
        $listings = Listing::where('status', 'published')->take(2)->get();
        foreach ($listings as $listing) {
            DB::table('favorites')->updateOrInsert(['user_id' => $u->id, 'listing_id' => $listing->id], ['created_at' => now(), 'updated_at' => now()]);
        }DB::table('saved_searches')->updateOrInsert(['user_id' => $u->id, 'name' => 'Villas à Cotonou'], ['criteria' => json_encode(['query' => 'villa', 'city' => 'Cotonou', 'type' => 'villa']), 'alerts_enabled' => true, 'created_at' => now(), 'updated_at' => now()]);
        if ($listings->isNotEmpty()) {
            DB::table('visit_requests')->updateOrInsert(['listing_id' => $listings->first()->id, 'requester_id' => $u->id], ['requested_at' => now()->addDays(3), 'comment' => 'Disponible en fin de matinée.', 'status' => 'confirmed', 'created_at' => now(), 'updated_at' => now()]);
        }
    }
}
