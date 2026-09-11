<?php

namespace Database\Seeders;

use App\Models\Property;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class AuditLogSeeder extends Seeder
{
    public function run(): void
    {
        $property = Property::firstOrFail();

        DB::table('audit_logs')->updateOrInsert(
            ['user_id' => $property->owner_id, 'action' => 'property.created.demo'],
            ['auditable_type' => Property::class, 'auditable_id' => $property->id, 'before' => null, 'after' => json_encode(['name' => $property->name]), 'ip_address' => '127.0.0.1', 'user_agent' => 'VIMMO Seeder', 'created_at' => now(), 'updated_at' => now()],
        );
    }
}
