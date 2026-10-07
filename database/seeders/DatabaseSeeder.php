<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call(EventCategorySeeder::class);

        if (app()->environment('testing')) {
            $this->call(DemoDatabaseSeeder::class);
        }
    }
}
