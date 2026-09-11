<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tickets', function (Blueprint $t) {
            $t->id();
            $t->foreignId('ticket_order_id')->constrained()->cascadeOnDelete();
            $t->foreignId('ticket_type_id')->constrained()->cascadeOnDelete();
            $t->string('code')->unique();
            $t->enum('status', ['valid', 'used', 'cancelled', 'expired'])->default('valid');
            $t->timestamp('scanned_at')->nullable();
            $t->foreignId('scanned_by')->nullable()->constrained('users')->nullOnDelete();
            $t->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tickets');
    }
};
