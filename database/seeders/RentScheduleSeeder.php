<?php

namespace Database\Seeders;

use App\Models\LeaseContract;
use App\Models\RentSchedule;
use Illuminate\Database\Seeder;

class RentScheduleSeeder extends Seeder
{
    public function run(): void
    {
        $c = LeaseContract::firstOrFail();
        for ($m = 2; $m <= 12; $m++) {
            RentSchedule::updateOrCreate(['lease_contract_id' => $c->id, 'period_start' => sprintf('2026-%02d-01', $m)], ['period_end' => date('Y-m-t', strtotime("2026-$m-01")), 'due_date' => sprintf('2026-%02d-05', $m), 'amount' => 150000, 'paid_amount' => $m < 9 ? 150000 : 0, 'status' => $m < 9 ? 'paid' : ($m === 9 ? 'due' : 'upcoming')]);
        }
    }
}
