<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('kkiapay_transactions', function (Blueprint $table) {
            $table->id();
            $table->morphs('payable');
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->uuid('partner_id')->unique();
            $table->string('provider_transaction_id')->nullable()->unique();
            $table->decimal('amount', 14, 2);
            $table->string('currency', 3)->default('XOF');
            $table->string('status', 24)->default('initiated')->index();
            $table->json('provider_payload')->nullable();
            $table->string('failure_code')->nullable();
            $table->text('failure_message')->nullable();
            $table->timestamp('verified_at')->nullable();
            $table->timestamp('failed_at')->nullable();
            $table->timestamps();

            $table->unique(['payable_type', 'payable_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('kkiapay_transactions');
    }
};
