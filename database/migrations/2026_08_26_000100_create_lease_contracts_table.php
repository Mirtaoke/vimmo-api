<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('lease_contracts', function (Blueprint $t) {
            $t->id();
            $t->foreignId('unit_id')->constrained()->cascadeOnDelete();
            $t->foreignId('owner_id')->constrained('users')->cascadeOnDelete();
            $t->foreignId('tenant_id')->constrained('users')->cascadeOnDelete();
            $t->string('reference')->unique();
            $t->date('starts_at');
            $t->date('ends_at')->nullable();
            $t->decimal('rent_amount', 14, 2);
            $t->decimal('deposit_amount', 14, 2)->default(0);
            $t->decimal('charges_amount', 14, 2)->default(0);
            $t->unsignedTinyInteger('due_day')->default(5);
            $t->enum('status', ['draft', 'pending_signature', 'active', 'ended'])->default('draft');
            $t->string('document_path')->nullable();
            $t->text('terms')->nullable();
            $t->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('lease_contracts');
    }
};
