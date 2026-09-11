<?php

namespace Database\Seeders;

use App\Models\Payment;
use App\Models\Receipt;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class ReceiptSeeder extends Seeder
{
    public function run(): void
    {
        $p = Payment::where('status', 'confirmed')->firstOrFail();
        Receipt::updateOrCreate(['payment_id' => $p->id], ['reference' => 'QTT-DEMO-2026-001', 'verification_token' => (string) Str::uuid(), 'generated_at' => now()->subDays(7)]);
    }
}
