<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('rent_schedules', function (Blueprint $t) {
            $t->id();
            $t->foreignId('lease_contract_id')->constrained()->cascadeOnDelete();
            $t->date('period_start');
            $t->date('period_end');
            $t->date('due_date');
            $t->decimal('amount', 14, 2);
            $t->decimal('paid_amount', 14, 2)->default(0);
            $t->enum('status', ['upcoming', 'due', 'partial', 'paid', 'late', 'unpaid'])->default('upcoming');
            $t->timestamps();
            $t->unique(['lease_contract_id', 'period_start']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('rent_schedules');
    }
};
