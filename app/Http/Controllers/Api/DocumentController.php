<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\LeaseContract;
use App\Models\Media;
use App\Support\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class DocumentController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();
        $query = Media::with('mediable')->where('collection', 'documents');

        if ($user->role === 'owner') {
            $query->where(function ($q) use ($user) {
                $q->where('user_id', $user->id)
                    ->orWhereHasMorph('mediable', [LeaseContract::class], fn ($contract) => $contract->where('owner_id', $user->id));
            });
        } elseif ($user->role === 'tenant') {
            $query->whereHasMorph('mediable', [LeaseContract::class], fn ($contract) => $contract->where('tenant_id', $user->id));
        } else {
            $query->where('user_id', $user->id);
        }

        if ($request->filled('contract_id')) {
            $query->where('mediable_type', LeaseContract::class)
                ->where('mediable_id', $request->integer('contract_id'));
        }

        return ApiResponse::success($query->latest()->get()->map(fn (Media $media) => $this->resource($media)));
    }

    public function store(Request $request)
    {
        abort_unless($request->user()->role === 'owner', 403);
        $data = $request->validate([
            'contract_id' => 'required|exists:lease_contracts,id',
            'title' => 'required|string|max:180',
            'type' => 'required|in:contract,receipt,inspection,identity,certificate,plan,other',
            'document' => 'required|file|mimes:pdf,jpg,jpeg,png,doc,docx|max:15360',
        ]);
        $contract = LeaseContract::where('owner_id', $request->user()->id)->findOrFail($data['contract_id']);
        $file = $request->file('document');
        $media = $contract->media()->create([
            'user_id' => $request->user()->id,
            'collection' => 'documents',
            'label' => $data['title'],
            'disk' => 'private',
            'path' => $file->store('contracts/'.$contract->id, 'private'),
            'mime_type' => $file->getMimeType(),
            'size' => $file->getSize(),
            'metadata' => ['type' => $data['type'], 'original_name' => $file->getClientOriginalName()],
        ]);

        \DB::table('notifications')->insert(['user_id' => $contract->tenant_id, 'type' => 'document', 'title' => 'Nouveau document', 'body' => $data['title'].' est disponible dans vos documents.', 'data' => json_encode(['document_id' => $media->id, 'contract_id' => $contract->id]), 'created_at' => now(), 'updated_at' => now()]);

        return ApiResponse::success($this->resource($media), 'Document importé et partagé avec le locataire.', 201);
    }

    public function download(Request $request, Media $media)
    {
        abort_unless($media->collection === 'documents' && $this->canAccess($request, $media), 403);
        abort_unless(Storage::disk($media->disk)->exists($media->path), 404, 'Le fichier demandé est introuvable.');
        $name = $media->metadata['original_name'] ?? basename($media->path);

        $content = Storage::disk($media->disk)->get($media->path);
        $safeName = str_replace(['"', "\r", "\n"], '', Str::ascii($name));

        return response($content, 200, [
            'Content-Type' => $media->mime_type ?: 'application/octet-stream',
            'Content-Length' => (string) strlen($content),
            'Content-Disposition' => 'attachment; filename="'.$safeName.'"',
            'Cache-Control' => 'private, no-store, max-age=0',
        ]);
    }

    public function downloadChunk(Request $request, Media $media)
    {
        abort_unless($media->collection === 'documents' && $this->canAccess($request, $media), 403);
        $disk = Storage::disk($media->disk);
        abort_unless($disk->exists($media->path), 404, 'Le fichier demandé est introuvable.');
        $offset = max(0, $request->integer('offset'));
        $stream = $disk->readStream($media->path);
        abort_unless(is_resource($stream), 404, 'Le fichier demandé est introuvable.');
        try {
            if ($offset > 0) {
                fseek($stream, $offset);
            }
            $bytes = fread($stream, 256 * 1024) ?: '';
        } finally {
            fclose($stream);
        }
        $total = $disk->size($media->path);
        $nextOffset = $offset + strlen($bytes);

        return ApiResponse::success([
            'content' => base64_encode($bytes),
            'offset' => $offset,
            'next_offset' => $nextOffset,
            'total' => $total,
            'done' => $nextOffset >= $total,
            'name' => $media->metadata['original_name'] ?? basename($media->path),
            'mime_type' => $media->mime_type ?: 'application/octet-stream',
        ]);
    }

    private function canAccess(Request $request, Media $media): bool
    {
        if ($media->user_id === $request->user()->id) {
            return true;
        }
        if (! $media->mediable instanceof LeaseContract) {
            return false;
        }

        return in_array($request->user()->id, [$media->mediable->owner_id, $media->mediable->tenant_id], true);
    }

    private function resource(Media $media): array
    {
        return [
            'id' => $media->id,
            'title' => $media->label,
            'type' => $media->metadata['type'] ?? 'other',
            'original_name' => $media->metadata['original_name'] ?? basename($media->path),
            'mime_type' => $media->mime_type,
            'size' => $media->size,
            'contract_id' => $media->mediable instanceof LeaseContract ? $media->mediable_id : null,
            'created_at' => $media->created_at,
            'download_path' => '/documents/'.$media->id.'/download',
        ];
    }
}
