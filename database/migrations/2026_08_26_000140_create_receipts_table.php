<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('receipts', function (Blueprint $t) {
            $t->id();
            $t->foreignId('payment_id')->unique()->constrained()->cascadeOnDelete();
            $t->string('reference')->unique();
            $t->string('document_path')->nullable();
            $t->string('verification_token')->unique();
            $t->timestamp('generated_at');
            $t->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('receipts');
    }
};
