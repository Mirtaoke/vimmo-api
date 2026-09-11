<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('inspections', function (Blueprint $t) {
            $t->id();
            $t->foreignId('lease_contract_id')->constrained()->cascadeOnDelete();
            $t->foreignId('created_by')->constrained('users')->cascadeOnDelete();
            $t->string('reference')->unique();
            $t->enum('type', ['entry', 'exit', 'intermediate']);
            $t->date('inspection_date');
            $t->enum('status', ['draft', 'owner_validated', 'tenant_validated', 'completed', 'disputed'])->default('draft');
            $t->unsignedInteger('version')->default(1);
            $t->json('readings')->nullable();
            $t->json('keys')->nullable();
            $t->json('equipment')->nullable();
            $t->string('document_path')->nullable();
            $t->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('inspections');
    }
};
