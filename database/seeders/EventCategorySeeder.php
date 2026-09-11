<?php

namespace Database\Seeders;

use App\Models\EventCategory;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class EventCategorySeeder extends Seeder
{
    public function run(): void
    {
        foreach (['Concert', 'Festival', 'Spectacle', 'Sport', 'Conférence', 'Formation', 'Culture', 'Famille', 'Professionnel'] as $n) {
            EventCategory::updateOrCreate(['name' => $n], ['slug' => Str::slug($n)]);
        }
    }
}
