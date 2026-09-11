<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payment_schedule', function (Blueprint $t) {
            $t->foreignId('payment_id')->constrained()->cascadeOnDelete();
            $t->foreignId('rent_schedule_id')->constrained()->cascadeOnDelete();
            $t->decimal('amount', 14, 2);
            $t->primary(['payment_id', 'rent_schedule_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payment_schedule');
    }
};
