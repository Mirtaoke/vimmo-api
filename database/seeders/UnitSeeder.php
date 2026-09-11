<?php

namespace Database\Seeders;

use App\Models\Property;
use App\Models\Unit;
use Illuminate\Database\Seeder;

class UnitSeeder extends Seeder
{
    public function run(): void
    {
        $prices = [850000, 650000, 420000, 380000, 1200000, 180000, 475000, 525000, 300000, 560000, 740000, 260000, 345000];
        foreach (Property::where('is_private', false)->orderBy('id')->get()->values() as $index => $property) {
            Unit::updateOrCreate(
                ['property_id' => $property->id, 'reference' => 'LOG-'.str_pad((string) ($index + 1), 3, '0', STR_PAD_LEFT)],
                ['type' => $property->type, 'surface' => $property->surface, 'rooms' => $index % 3 + 3, 'bedrooms' => $index % 4 + 1, 'bathrooms' => $index % 2 + 1, 'monthly_rent' => $prices[$index] ?? 250000, 'status' => $index === 0 ? 'occupied' : 'available', 'amenities' => ['parking', 'climatisation', 'eau', 'sécurité', 'fibre']],
            );
        }
    }
}
