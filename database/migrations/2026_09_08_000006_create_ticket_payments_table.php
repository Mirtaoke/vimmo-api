<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ticket_payments', function (Blueprint $t) {
            $t->id();
            $t->foreignId('ticket_order_id')->constrained()->cascadeOnDelete();
            $t->string('reference')->unique();
            $t->string('provider');
            $t->string('provider_reference')->nullable();
            $t->decimal('amount', 14, 2);
            $t->string('currency', 3)->default('XOF');
            $t->enum('status', ['initiated', 'paid', 'failed', 'refunded'])->default('initiated');
            $t->json('metadata')->nullable();
            $t->timestamp('paid_at')->nullable();
            $t->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ticket_payments');
    }
};
