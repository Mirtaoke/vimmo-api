<?php

namespace Database\Seeders;

use App\Models\Property;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class AssetShareSeeder extends Seeder
{
    public function run(): void
    {
        $recipients = User::whereIn('role', ['tenant', 'seeker'])->get()->values();
        foreach (Property::where('is_private', true)->get() as $index => $property) {
            $recipient = $recipients[$index % $recipients->count()];
            DB::table('asset_shares')->updateOrInsert(['property_id' => $property->id, 'shared_with_id' => $recipient->id], ['shared_by' => $property->owner_id, 'name' => $recipient->name, 'email' => $recipient->email, 'permission' => $index % 2 === 0 ? 'documents' : 'view', 'token' => (string) Str::uuid(), 'revoked_at' => null, 'created_at' => now(), 'updated_at' => now()]);
        }
    }
}
