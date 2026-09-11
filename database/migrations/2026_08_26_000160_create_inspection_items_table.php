<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('inspection_items', function (Blueprint $t) {
            $t->id();
            $t->foreignId('inspection_id')->constrained()->cascadeOnDelete();
            $t->string('room');
            $t->string('element');
            $t->enum('condition', ['new', 'very_good', 'good', 'average', 'bad', 'out_of_order', 'not_applicable']);
            $t->text('comment')->nullable();
            $t->boolean('anomaly')->default(false);
            $t->json('exit_comparison')->nullable();
            $t->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('inspection_items');
    }
};
