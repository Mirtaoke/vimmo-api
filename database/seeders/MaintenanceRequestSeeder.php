<?php

namespace Database\Seeders;

use App\Models\LeaseContract;
use App\Models\MaintenanceRequest;
use Illuminate\Database\Seeder;

class MaintenanceRequestSeeder extends Seeder
{
    public function run(): void
    {
        $c = LeaseContract::firstOrFail();
        MaintenanceRequest::updateOrCreate(['unit_id' => $c->unit_id, 'title' => 'Fuite sous l’évier'], ['reported_by' => $c->tenant_id, 'category' => 'Plomberie', 'description' => 'Une fuite légère apparaît lorsque le robinet de la cuisine est ouvert.', 'priority' => 'high', 'status' => 'processing', 'scheduled_at' => now()->addDays(2)]);
    }
}
