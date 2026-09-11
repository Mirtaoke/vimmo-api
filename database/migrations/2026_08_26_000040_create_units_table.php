<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('units', function (Blueprint $t) {
            $t->id();
            $t->foreignId('property_id')->constrained()->cascadeOnDelete();
            $t->string('reference');
            $t->string('type');
            $t->decimal('surface', 10, 2)->nullable();
            $t->unsignedSmallInteger('rooms')->default(0);
            $t->unsignedSmallInteger('bedrooms')->default(0);
            $t->unsignedSmallInteger('bathrooms')->default(0);
            $t->decimal('monthly_rent', 14, 2)->default(0);
            $t->enum('status', ['available', 'reserved', 'occupied', 'maintenance', 'inspection', 'pending', 'inactive'])->default('available');
            $t->json('amenities')->nullable();
            $t->timestamps();
            $t->unique(['property_id', 'reference']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('units');
    }
};
