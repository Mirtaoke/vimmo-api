<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('inspection_disputes', function (Blueprint $t) {
            $t->id();
            $t->foreignId('inspection_id')->constrained()->cascadeOnDelete();
            $t->foreignId('inspection_item_id')->nullable()->constrained()->cascadeOnDelete();
            $t->foreignId('user_id')->constrained()->cascadeOnDelete();
            $t->text('comment');
            $t->text('response')->nullable();
            $t->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('inspection_disputes');
    }
};
