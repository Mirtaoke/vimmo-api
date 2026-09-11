<?php

namespace Database\Seeders;

use App\Models\Inspection;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class InspectionWorkflowSeeder extends Seeder
{
    public function run(): void
    {
        $inspection = Inspection::with(['contract', 'items'])->firstOrFail();
        $now = now();

        foreach ([$inspection->contract->owner_id, $inspection->contract->tenant_id] as $userId) {
            DB::table('inspection_validations')->updateOrInsert(
                ['inspection_id' => $inspection->id, 'user_id' => $userId],
                ['method' => 'electronic', 'ip_address' => '127.0.0.1', 'validated_at' => $now],
            );
        }

        DB::table('inspection_disputes')->updateOrInsert(
            ['inspection_id' => $inspection->id, 'user_id' => $inspection->contract->tenant_id],
            ['inspection_item_id' => $inspection->items->first()?->id, 'comment' => 'Une petite trace est visible sur le mur.', 'response' => 'Observation ajoutée au document final.', 'created_at' => $now, 'updated_at' => $now],
        );

        DB::table('inspection_versions')->updateOrInsert(
            ['inspection_id' => $inspection->id, 'version' => 1],
            ['created_by' => $inspection->created_by, 'snapshot' => json_encode($inspection->load('items')->toArray()), 'reason' => 'Version initiale validée par les deux parties.', 'created_at' => $now, 'updated_at' => $now],
        );
    }
}
