<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        if (DB::getDriverName() === 'mysql') {
            DB::statement("ALTER TABLE users MODIFY role ENUM('seeker','owner','tenant','organizer','family_member','admin') NOT NULL DEFAULT 'seeker'");
        }
    }

    public function down(): void
    {
        if (DB::getDriverName() === 'mysql') {
            DB::table('users')->where('role', 'family_member')->update(['role' => 'seeker']);
            DB::statement("ALTER TABLE users MODIFY role ENUM('seeker','owner','tenant','organizer','admin') NOT NULL DEFAULT 'seeker'");
        }
    }
};
