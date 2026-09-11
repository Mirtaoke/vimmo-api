<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('maintenance_requests', function (Blueprint $t) {
            $t->id();
            $t->foreignId('unit_id')->constrained()->cascadeOnDelete();
            $t->foreignId('reported_by')->constrained('users')->cascadeOnDelete();
            $t->string('category');
            $t->string('title');
            $t->text('description');
            $t->enum('priority', ['low', 'normal', 'high', 'urgent'])->default('normal');
            $t->enum('status', ['new', 'received', 'processing', 'scheduled', 'resolved', 'closed'])->default('new');
            $t->dateTime('scheduled_at')->nullable();
            $t->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('maintenance_requests');
    }
};
