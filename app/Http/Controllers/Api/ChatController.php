<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\Media;
use App\Models\Message;
use App\Support\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ChatController extends Controller
{
    private function authorizeConversation(Request $r, Conversation $c): void
    {
        abort_unless($c->participants()->where('users.id', $r->user()->id)->exists(), 403);
    }

    public function index(Request $r)
    {
        return ApiResponse::success(Conversation::with(['unit.property', 'participants:id,name,phone,avatar_path', 'messages' => fn ($q) => $q->latest()->limit(1)])->whereHas('participants', fn ($q) => $q->where('users.id', $r->user()->id))->latest('updated_at')->get());
    }

    public function store(Request $r)
    {
        $d = $r->validate(['participant_id' => 'required|exists:users,id', 'unit_id' => 'nullable|exists:units,id', 'listing_id' => 'nullable|exists:listings,id', 'subject' => 'nullable|string']);
        abort_if((int) $d['participant_id'] === $r->user()->id, 422, 'Vous ne pouvez pas discuter avec vous-même.');

        return DB::transaction(function () use ($d, $r) {
            $ids = collect([$r->user()->id, (int) $d['participant_id']])->sort()->values();
            $existing = Conversation::where('unit_id', $d['unit_id'] ?? null)->whereHas('participants', fn ($q) => $q->where('users.id', $ids[0]))->whereHas('participants', fn ($q) => $q->where('users.id', $ids[1]))->first();
            if ($existing) {
                return ApiResponse::success($existing->load(['participants', 'unit.property']), 'Conversation existante.');
            }$c = Conversation::create($d);
            $c->participants()->attach($ids);

            return ApiResponse::success($c->load(['participants', 'unit.property']), 'Conversation créée.', 201);
        });
    }

    public function messages(Request $r, Conversation $conversation)
    {
        $this->authorizeConversation($r, $conversation);
        $conversation->participants()->updateExistingPivot($r->user()->id, ['last_read_at' => now()]);

        return ApiResponse::success($conversation->messages()->with(['sender:id,name,avatar_path', 'media'])->oldest()->paginate(50));
    }

    public function send(Request $r, Conversation $conversation)
    {
        $this->authorizeConversation($r, $conversation);
        $d = $r->validate(['body' => 'nullable|string|required_without:attachments', 'attachments' => 'nullable|array|max:5', 'attachments.*' => 'file|max:20480']);

        return DB::transaction(function () use ($r, $conversation, $d) {
            $m = $conversation->messages()->create(['sender_id' => $r->user()->id, 'body' => $d['body'] ?? null, 'type' => $r->hasFile('attachments') ? 'attachment' : 'text']);
            foreach ($r->file('attachments', []) as $file) {
                Media::create(['user_id' => $r->user()->id, 'mediable_type' => Message::class, 'mediable_id' => $m->id, 'collection' => 'attachments', 'label' => $file->getClientOriginalName(), 'disk' => 'private', 'path' => $file->store('chat', 'private'), 'mime_type' => $file->getMimeType(), 'size' => $file->getSize(), 'metadata' => ['original_name' => $file->getClientOriginalName()]]);
            }$conversation->touch();
            foreach ($conversation->participants()->where('users.id', '!=', $r->user()->id)->pluck('users.id') as $recipient) {
                DB::table('notifications')->insert(['user_id' => $recipient, 'type' => 'message', 'title' => 'Nouveau message', 'body' => $d['body'] ?? 'Une pièce jointe a été envoyée.', 'data' => json_encode(['conversation_id' => $conversation->id, 'message_id' => $m->id]), 'created_at' => now(), 'updated_at' => now()]);
            }

return ApiResponse::success($m->load(['sender', 'media']),'Message envoyé.',201);
        });
    }
}
