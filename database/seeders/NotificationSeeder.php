<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class NotificationSeeder extends Seeder
{
    public function run(): void
    {
        foreach (User::all() as $u) {
            DB::table('notifications')->updateOrInsert(['user_id' => $u->id, 'type' => 'welcome'], ['title' => 'Bienvenue sur VIMMO', 'body' => 'Votre espace VIMMO est prêt.', 'data' => json_encode([]), 'created_at' => now(), 'updated_at' => now()]);
        }
    }
}
