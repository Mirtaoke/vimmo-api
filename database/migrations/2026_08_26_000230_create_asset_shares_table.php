<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('asset_shares', function (Blueprint $t) {
            $t->id();
            $t->foreignId('property_id')->constrained()->cascadeOnDelete();
            $t->foreignId('shared_by')->constrained('users')->cascadeOnDelete();
            $t->string('name');
            $t->string('email');
            $t->enum('permission', ['view', 'documents', 'contribute', 'manage'])->default('view');
            $t->string('token')->unique();
            $t->timestamp('revoked_at')->nullable();
            $t->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('asset_shares');
    }
};
