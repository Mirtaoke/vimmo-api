<?php

namespace Database\Seeders;

use App\Models\Conversation;
use App\Models\Message;
use App\Models\User;
use Illuminate\Database\Seeder;

class MessageSeeder extends Seeder
{
    public function run(): void
    {
        $c = Conversation::firstOrFail();
        $o = User::where('role', 'owner')->firstOrFail();
        Message::firstOrCreate(['conversation_id' => $c->id, 'sender_id' => $o->id, 'body' => 'Bonjour Aïcha, votre dossier locatif est disponible.']);
    }
}
