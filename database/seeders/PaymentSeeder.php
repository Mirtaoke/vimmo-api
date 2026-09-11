<?php

namespace Database\Seeders;

use App\Models\LeaseContract;
use App\Models\Payment;
use App\Models\RentSchedule;
use App\Models\User;
use Illuminate\Database\Seeder;

class PaymentSeeder extends Seeder
{
    public function run(): void
    {
        $c = LeaseContract::firstOrFail();
        $t = User::where('role', 'tenant')->firstOrFail();
        $o = User::where('role', 'owner')->firstOrFail();
        $s = RentSchedule::where('lease_contract_id', $c->id)->firstOrFail();
        $p = Payment::updateOrCreate(['reference' => 'PAY-DEMO-2026-001'], ['lease_contract_id' => $c->id, 'payer_id' => $t->id, 'confirmed_by' => $o->id, 'amount' => $s->amount, 'method' => 'mtn_momo', 'status' => 'confirmed', 'paid_at' => now()->subDays(8), 'confirmed_at' => now()->subDays(7), 'note' => 'Paiement de démonstration confirmé.']);
        $p->schedules()->syncWithoutDetaching([$s->id => ['amount' => $s->amount]]);
        $s->update(['paid_amount' => $s->amount, 'status' => 'paid']);
    }
}
