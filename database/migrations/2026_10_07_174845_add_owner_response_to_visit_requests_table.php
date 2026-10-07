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
        Schema::table('visit_requests', function (Blueprint $table) {
            $table->text('owner_note')->nullable()->after('comment');
            $table->dateTime('proposed_at')->nullable()->after('owner_note');
            $table->text('rejection_reason')->nullable()->after('proposed_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('visit_requests', function (Blueprint $table) {
            $table->dropColumn(['owner_note', 'proposed_at', 'rejection_reason']);
        });
    }
};
