<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $ids = DB::table('rent_schedules')
            ->join('lease_contracts', 'lease_contracts.id', '=', 'rent_schedules.lease_contract_id')
            ->whereColumn('rent_schedules.due_date', '<', 'lease_contracts.starts_at')
            ->whereNotIn('rent_schedules.status', ['paid'])
            ->pluck('rent_schedules.id');

        if ($ids->isNotEmpty()) {
            DB::table('rent_schedules')->whereIn('id', $ids)->delete();
        }
    }

    public function down(): void
    {
        // Une échéance antérieure au contrat ne doit pas être recréée.
    }
};
