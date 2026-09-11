<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('listings', function (Blueprint $t) {
            $t->id();
            $t->foreignId('owner_id')->constrained('users')->cascadeOnDelete();
            $t->foreignId('unit_id')->constrained()->cascadeOnDelete();
            $t->string('title');
            $t->text('description');
            $t->decimal('price', 14, 2);
            $t->decimal('deposit', 14, 2)->default(0);
            $t->decimal('charges', 14, 2)->default(0);
            $t->date('available_from')->nullable();
            $t->enum('status', ['draft', 'pending', 'published', 'reserved', 'rented', 'suspended', 'archived'])->default('draft')->index();
            $t->boolean('is_verified')->default(false);
            $t->timestamp('published_at')->nullable();
            $t->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('listings');
    }
};
