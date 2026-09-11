<?php

namespace Database\Seeders;

use App\Models\LeaseContract;
use App\Models\Unit;
use App\Models\User;
use Illuminate\Database\Seeder;

class LeaseContractSeeder extends Seeder
{
    public function run(): void
    {
        $u = Unit::firstOrFail();
        $o = User::where('role', 'owner')->firstOrFail();
        $t = User::where('role', 'tenant')->firstOrFail();
        LeaseContract::updateOrCreate(['reference' => 'VIM-CTR-2026-0012'], ['unit_id' => $u->id, 'owner_id' => $o->id, 'tenant_id' => $t->id, 'starts_at' => '2026-02-01', 'ends_at' => '2027-01-31', 'rent_amount' => 150000, 'deposit_amount' => 300000, 'due_day' => 5, 'status' => 'active']);
    }
}
