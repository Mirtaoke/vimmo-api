<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class NotificationSeeder extends Seeder
{
    public function run(): void
    {
        DB::table('notifications')
            ->where('type', 'welcome')
            ->where('title', 'Bienvenue sur VIMMO')
            ->delete();
    }
}
