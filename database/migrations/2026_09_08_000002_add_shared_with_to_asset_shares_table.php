<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('asset_shares', function (Blueprint $table) {
            $table->foreignId('shared_with_id')->nullable()->after('shared_by')->constrained('users')->cascadeOnDelete();
        });
        foreach (DB::table('asset_shares')->get() as $share) {
            $user = DB::table('users')->whereRaw('LOWER(email)=?', [strtolower($share->email)])->first();
            if ($user) {
                DB::table('asset_shares')->where('id', $share->id)->update(['shared_with_id' => $user->id]);
            }
        }Schema::table('asset_shares', function (Blueprint $table) {
            $table->unique(['property_id', 'shared_with_id']);
        });
    }

    public function down(): void
    {
        Schema::table('asset_shares', function (Blueprint $table) {
            $table->dropUnique(['property_id', 'shared_with_id']);
            $table->dropConstrainedForeignId('shared_with_id');
        });
    }
};
