<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('pending_registrations', function (Blueprint $table) {
            $table->unsignedTinyInteger('resend_count')->default(0)->after('otp_hash');
            $table->timestamp('last_sent_at')->nullable()->after('resend_count');
        });
    }

    public function down(): void
    {
        Schema::table('pending_registrations', function (Blueprint $table) {
            $table->dropColumn(['resend_count', 'last_sent_at']);
        });
    }
};
