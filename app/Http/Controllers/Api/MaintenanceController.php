<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\MaintenanceComment;
use App\Models\MaintenanceRequest;
use App\Models\Media;
use App\Models\Unit;
use App\Support\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class MaintenanceController extends Controller
{
    private function authorized(Request $r, MaintenanceRequest $m): bool
    {
        return $m->reported_by === $r->user()->id || $m->unit->property->owner_id === $r->user()->id;
    }

    public function index(Request $r)
    {
        $q = MaintenanceRequest::with(['unit.property', 'reporter:id,name,email,phone', 'media', 'comments.user:id,name']);
        if ($r->user()->role === 'tenant') {
            $q->where('reported_by', $r->user()->id);
        } else {
            $q->whereHas('unit.property', fn ($x) => $x->where('owner_id', $r->user()->id));
        }if ($r->filled('status')) {
            $q->where('status', $r->status);
        }

return ApiResponse::success($q->latest()->get());
    }

    public function show(Request $r, MaintenanceRequest $maintenance)
    {
        abort_unless($this->authorized($r, $maintenance), 403);

        return ApiResponse::success($maintenance->load(['unit.property', 'reporter:id,name,email,phone', 'media', 'comments.user:id,name']));
    }

    public function store(Request $r)
    {
        $d = $r->validate(['unit_id' => 'required|exists:units,id', 'category' => 'required|in:fuite,panne_electrique,serrure,plomberie,climatisation,toiture,autre', 'title' => 'required|string|max:180', 'description' => 'required|string', 'priority' => 'nullable|in:low,normal,high,urgent', 'attachments' => 'nullable|array|max:5', 'attachments.*' => 'file|mimes:jpg,jpeg,png,mp4,mov,pdf|max:30720']);
        $unit = Unit::findOrFail($d['unit_id']);
        abort_unless($unit->contracts()->where('tenant_id', $r->user()->id)->where('status', 'active')->exists(), 403, 'Ce logement n’est pas lié à votre contrat actif.');
        $attachments = $r->file('attachments', []);
        unset($d['attachments']);
        $maintenance = MaintenanceRequest::create([...$d, 'reported_by' => $r->user()->id]);
        foreach ($attachments as $file) {
            Media::create(['user_id' => $r->user()->id, 'mediable_type' => MaintenanceRequest::class, 'mediable_id' => $maintenance->id, 'collection' => 'evidence', 'disk' => 'private', 'path' => $file->store('maintenance', 'private'), 'mime_type' => $file->getMimeType(), 'size' => $file->getSize(), 'metadata' => ['original_name' => $file->getClientOriginalName()]]);
        }$this->notify($unit->property->owner_id, 'maintenance', 'Nouvelle réclamation', $maintenance->title, ['maintenance_id' => $maintenance->id]);

        return ApiResponse::success($maintenance->load('media'), 'Problème signalé.', 201);
    }

    public function status(Request $r, MaintenanceRequest $maintenance)
    {
        abort_unless($maintenance->unit->property->owner_id === $r->user()->id, 403);
        $d = $r->validate(['status' => 'required|in:received,processing,scheduled,resolved,closed', 'scheduled_at' => 'nullable|required_if:status,scheduled|date|after:now']);
        $maintenance->update($d);
        $this->notify($maintenance->reported_by, 'maintenance', 'Intervention mise à jour', 'Votre réclamation « '.$maintenance->title.' » est maintenant : '.$d['status'], ['maintenance_id' => $maintenance->id]);

        return ApiResponse::success($maintenance->fresh(['comments', 'media']), 'Intervention mise à jour.');
    }

    public function comment(Request $r, MaintenanceRequest $maintenance)
    {
        abort_unless($this->authorized($r, $maintenance), 403);
        $d = $r->validate(['comment' => 'required|string|max:3000']);
        $comment = MaintenanceComment::create([...$d, 'maintenance_request_id' => $maintenance->id, 'user_id' => $r->user()->id]);
        $recipient = $maintenance->reported_by === $r->user()->id ? $maintenance->unit->property->owner_id : $maintenance->reported_by;
        $this->notify($recipient, 'maintenance_comment', 'Nouveau commentaire', $d['comment'], ['maintenance_id' => $maintenance->id]);

        return ApiResponse::success($comment->load('user:id,name'), 'Commentaire ajouté.', 201);
    }

    private function notify(int $userId, string $type, string $title, string $body, array $data): void
    {
        DB::table('notifications')->insert(['user_id' => $userId, 'type' => $type, 'title' => $title, 'body' => $body, 'data' => json_encode($data), 'created_at' => now(), 'updated_at' => now()]);
    }
}
