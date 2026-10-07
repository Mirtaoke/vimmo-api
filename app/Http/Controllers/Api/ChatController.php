<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\LeaseContract;
use App\Models\Listing;
use App\Models\Media;
use App\Models\Message;
use App\Models\Unit;
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
        return ApiResponse::success(Conversation::with(['unit.media', 'unit.property.media', 'participants:id,name,phone,avatar_path', 'messages' => fn ($q) => $q->latest()->limit(1)])->whereHas('participants', fn ($q) => $q->where('users.id', $r->user()->id))->latest('updated_at')->get());
    }

    public function store(Request $r)
    {
        $d = $r->validate(['participant_id' => 'required|exists:users,id', 'unit_id' => 'nullable|exists:units,id', 'listing_id' => 'nullable|exists:listings,id', 'subject' => 'nullable|string']);
        abort_if((int) $d['participant_id'] === $r->user()->id, 422, 'Vous ne pouvez pas discuter avec vous-même.');
        $this->authorizeNewConversation($r, $d);

        return DB::transaction(function () use ($d, $r) {
            $ids = collect([$r->user()->id, (int) $d['participant_id']])->sort()->values();
            $existing = Conversation::where('unit_id', $d['unit_id'] ?? null)->whereHas('participants', fn ($q) => $q->where('users.id', $ids[0]))->whereHas('participants', fn ($q) => $q->where('users.id', $ids[1]))->first();
            if ($existing) {
                return ApiResponse::success($existing->load(['participants', 'unit.media', 'unit.property.media']), 'Conversation existante.');
            }
            $conversationData = collect($d)->except('participant_id')->all();
            $c = Conversation::create($conversationData);
            $c->participants()->attach($ids);

            return ApiResponse::success($c->load(['participants', 'unit.media', 'unit.property.media']), 'Conversation créée.', 201);
        });
    }

    private function authorizeNewConversation(Request $request, array $data): void
    {
        $user = $request->user();
        $participantId = (int) $data['participant_id'];
        $unitId = isset($data['unit_id']) ? (int) $data['unit_id'] : null;
        $listingId = isset($data['listing_id']) ? (int) $data['listing_id'] : null;

        $allowed = match ($user->role) {
            'seeker' => $listingId !== null && Listing::query()
                ->whereKey($listingId)
                ->where('owner_id', $participantId)
                ->where('status', 'published')
                ->when($unitId !== null, fn ($query) => $query->where('unit_id', $unitId))
                ->exists(),
            'owner' => $unitId !== null && LeaseContract::query()
                ->where('unit_id', $unitId)
                ->where('owner_id', $user->id)
                ->where('tenant_id', $participantId)
                ->exists(),
            'tenant' => $unitId !== null && LeaseContract::query()
                ->where('unit_id', $unitId)
                ->where('tenant_id', $user->id)
                ->where('owner_id', $participantId)
                ->exists(),
            default => false,
        };

        abort_unless($allowed, 403, 'Cette conversation ne correspond pas à votre relation avec ce bien.');
        if ($unitId !== null) {
            abort_unless(Unit::whereKey($unitId)->exists(), 422, 'Logement introuvable.');
        }
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

            return ApiResponse::success($m->load(['sender', 'media']), 'Message envoyé.', 201);
        });
    }
}
