<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('visit_requests', function (Blueprint $t) {
            $t->id();
            $t->foreignId('listing_id')->constrained()->cascadeOnDelete();
            $t->foreignId('requester_id')->constrained('users')->cascadeOnDelete();
            $t->dateTime('requested_at');
            $t->text('comment')->nullable();
            $t->enum('status', ['requested', 'accepted', 'confirmed', 'completed', 'cancelled'])->default('requested');
            $t->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('visit_requests');
    }
};
