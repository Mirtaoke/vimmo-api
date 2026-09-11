<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('rental_applications', function (Blueprint $t) {
            $t->id();
            $t->foreignId('listing_id')->constrained()->cascadeOnDelete();
            $t->foreignId('applicant_id')->constrained('users')->cascadeOnDelete();
            $t->text('message')->nullable();
            $t->json('profile_data')->nullable();
            $t->enum('status', ['submitted', 'reviewing', 'accepted', 'rejected', 'withdrawn'])->default('submitted');
            $t->text('owner_note')->nullable();
            $t->timestamps();
            $t->unique(['listing_id', 'applicant_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('rental_applications');
    }
};
