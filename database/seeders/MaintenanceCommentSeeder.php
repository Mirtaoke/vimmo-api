<?php

namespace Database\Seeders;

use App\Models\MaintenanceComment;
use App\Models\MaintenanceRequest;
use Illuminate\Database\Seeder;

class MaintenanceCommentSeeder extends Seeder
{
    public function run(): void
    {
        $request = MaintenanceRequest::with('unit.property')->firstOrFail();
        MaintenanceComment::firstOrCreate(['maintenance_request_id' => $request->id, 'user_id' => $request->reported_by, 'comment' => 'Le problème est toujours visible ce matin.']);
    }
}
