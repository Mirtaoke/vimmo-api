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
        }
        if (isset($c['type']) && ! in_array(mb_strtolower($unit->type), array_map('mb_strtolower', (array) $c['type']), true)) {
            return false;
        }
        foreach (['city', 'commune', 'district'] as $field) {
            if (isset($c[$field]) && ! str_contains(mb_strtolower((string) $property->{$field}), mb_strtolower((string) $c[$field]))) {
                return false;
            }
        }
        if (isset($c['zone'])) {
            $haystack = mb_strtolower(implode(' ', [$property->district, $property->commune, $property->city]));
            if (! str_contains($haystack, mb_strtolower((string) $c['zone']))) {
                return false;
            }
        }
        if (isset($c['min_price']) && (float) $listing->price < (float) $c['min_price']) {
            return false;
        }
        if (isset($c['max_price']) && (float) $listing->price > (float) $c['max_price']) {
            return false;
        }
        if (isset($c['bedrooms']) && $unit->bedrooms < (int) $c['bedrooms']) {
            return false;
        }
        if (isset($c['rooms']) && $unit->rooms < (int) $c['rooms']) {
            return false;
        }
        if (isset($c['min_surface']) && (float) $unit->surface < (float) $c['min_surface']) {
            return false;
        }
        if (isset($c['max_surface']) && (float) $unit->surface > (float) $c['max_surface']) {
            return false;
        }
        if (isset($c['availability']) && ! in_array($unit->status, explode(',', (string) $c['availability']), true)) {
            return false;
        }
        if (isset($c['available_from']) && (! $listing->available_from || $listing->available_from->gt($c['available_from']))) {
            return false;
        }
        $aliases = [
            'furnished' => ['furnished', 'meuble', 'meublé'],
            'parking' => ['parking'],
            'water' => ['water', 'eau'],
            'electricity' => ['electricity', 'électricité', 'electricite'],
            'air_conditioning' => ['air_conditioning', 'climatisation'],
            'security' => ['security', 'sécurité', 'securite'],
            'pool' => ['pool', 'piscine'],
            'terrace' => ['terrace', 'terrasse'],
        ];
        $unitAmenities = array_map('mb_strtolower', $unit->amenities ?? []);
        foreach ($aliases as $filter => $acceptedValues) {
            if ($this->isEnabled($c[$filter] ?? false) && ! array_intersect($acceptedValues, $unitAmenities)) {
                return false;
            }
        }

        return true;
    }

    private function isEnabled(mixed $value): bool
    {
        return in_array($value, [true, 1, '1', 'true', 'yes', 'on'], true);
    }
}
