<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('inspection_versions', function (Blueprint $t) {
            $t->id();
            $t->foreignId('inspection_id')->constrained()->cascadeOnDelete();
            $t->unsignedInteger('version');
            $t->foreignId('created_by')->constrained('users')->cascadeOnDelete();
            $t->json('snapshot');
            $t->text('reason');
            $t->timestamps();
            $t->unique(['inspection_id', 'version']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('inspection_versions');
    }
};
