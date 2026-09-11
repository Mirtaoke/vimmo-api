<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $t) {
            $t->string('first_name')->nullable();
            $t->string('last_name')->nullable();
            $t->string('phone')->nullable()->unique();
            $t->enum('role', ['seeker', 'owner', 'tenant', 'organizer', 'admin'])->default('seeker')->index();
            $t->string('avatar_path')->nullable();
            $t->boolean('is_active')->default(true);
            $t->timestamp('phone_verified_at')->nullable();
            $t->json('preferences')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('users', fn (Blueprint $t) => $t->dropColumn(['first_name', 'last_name', 'phone', 'role', 'avatar_path', 'is_active', 'phone_verified_at', 'preferences']));
    }
};
