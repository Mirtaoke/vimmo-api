<?php

namespace Database\Seeders;

use App\Models\Conversation;
use App\Models\Unit;
use App\Models\User;
use Illuminate\Database\Seeder;

class ConversationSeeder extends Seeder
{
    public function run(): void
    {
        $c = Conversation::firstOrCreate(['unit_id' => Unit::firstOrFail()->id, 'subject' => 'Appartement A01']);
        $c->participants()->syncWithoutDetaching(User::whereIn('role', ['owner', 'tenant'])->pluck('id'));
    }
}
