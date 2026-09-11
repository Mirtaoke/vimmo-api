<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payments', function (Blueprint $t) {
            $t->id();
            $t->foreignId('lease_contract_id')->constrained()->cascadeOnDelete();
            $t->foreignId('payer_id')->constrained('users')->cascadeOnDelete();
            $t->foreignId('confirmed_by')->nullable()->constrained('users')->nullOnDelete();
            $t->string('reference')->unique();
            $t->decimal('amount', 14, 2);
            $t->enum('method', ['cash', 'mtn_momo', 'moov_money', 'bank_transfer', 'cheque', 'other']);
            $t->enum('status', ['pending', 'confirmed', 'rejected'])->default('pending');
            $t->string('proof_path')->nullable();
            $t->timestamp('paid_at');
            $t->timestamp('confirmed_at')->nullable();
            $t->text('note')->nullable();
            $t->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};
