<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('events', function (Blueprint $t) {
            $t->id();
            $t->foreignId('organizer_id')->constrained('users')->cascadeOnDelete();
            $t->foreignId('event_category_id')->nullable()->constrained()->nullOnDelete();
            $t->string('title');
            $t->string('theme')->nullable();
            $t->string('dress_code')->nullable();
            $t->text('description');
            $t->text('experience')->nullable();
            $t->string('place');
            $t->text('place_description')->nullable();
            $t->decimal('latitude', 10, 7)->nullable();
            $t->decimal('longitude', 10, 7)->nullable();
            $t->dateTime('starts_at');
            $t->dateTime('ends_at');
            $t->enum('status', ['draft', 'published', 'suspended', 'ended'])->default('draft');
            $t->string('cover_path')->nullable();
            $t->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('events');
    }
};
