<?php

namespace App\Services;

use App\Models\Listing;
use Illuminate\Support\Facades\DB;

class ListingAlertService
{
    public function notifyFor(Listing $listing): void
    {
        $listing->loadMissing('unit.property');
        foreach (DB::table('saved_searches')->where('alerts_enabled', true)->where('user_id', '!=', $listing->owner_id)->get() as $search) {
            $criteria = json_decode($search->criteria, true) ?: [];
            if (! $this->matches($listing, $criteria)) {
                continue;
            }$exists = DB::table('notifications')->where('user_id', $search->user_id)->where('type', 'property_alert')->where('data', 'like', '%"listing_id":'.$listing->id.'%')->exists();
            if (! $exists) {
                DB::table('notifications')->insert(['user_id' => $search->user_id, 'type' => 'property_alert', 'title' => 'Nouveau logement correspondant', 'body' => $listing->title.' correspond à votre recherche « '.$search->name.' ».', 'data' => json_encode(['listing_id' => $listing->id, 'saved_search_id' => $search->id]), 'created_at' => now(), 'updated_at' => now()]);
            }
        }
    }

    private function matches(Listing $listing, array $c): bool
    {
        $unit = $listing->unit;
        $property = $unit->property;
        $q = mb_strtolower(trim((string) ($c['q'] ?? '')));
        if ($q !== '' && ! str_contains(mb_strtolower(implode(' ', [$listing->title, $listing->description, $property->name, $property->address, $property->district, $property->commune, $property->city])), $q)) {
            return false;
        }if (isset($c['type']) && ! in_array(mb_strtolower($unit->type), array_map('mb_strtolower', (array) $c['type']), true)) {
            return false;
        }if (isset($c['min_price']) && (float) $listing->price < (float) $c['min_price']) {
            return false;
        }if (isset($c['max_price']) && (float) $listing->price > (float) $c['max_price']) {
            return false;
        }if (isset($c['bedrooms']) && $unit->bedrooms < (int) $c['bedrooms']) {
            return false;
        }if (isset($c['rooms']) && $unit->rooms < (int) $c['rooms']) {
            return false;
        }if (isset($c['min_surface']) && (float) $unit->surface < (float) $c['min_surface']) {
            return false;
        }foreach (['parking', 'water', 'electricity', 'air_conditioning', 'security', 'pool', 'terrace', 'furnished'] as $amenity) {
            if (($c[$amenity] ?? false) && ! in_array($amenity, $unit->amenities ?? [], true)) {
                return false;
            }
        }

return true;
    }
}
