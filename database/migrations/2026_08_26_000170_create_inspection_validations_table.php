<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('inspection_validations', function (Blueprint $t) {
            $t->id();
            $t->foreignId('inspection_id')->constrained()->cascadeOnDelete();
            $t->foreignId('user_id')->constrained()->cascadeOnDelete();
            $t->string('method')->default('electronic');
            $t->string('ip_address')->nullable();
            $t->timestamp('validated_at');
            $t->unique(['inspection_id', 'user_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('inspection_validations');
    }
};
