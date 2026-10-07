<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Mail\PatrimonySharedMail;
use App\Models\InspectionItem;
use App\Models\MaintenanceRequest;
use App\Models\Media;
use App\Models\Message;
use App\Models\Property;
use App\Models\User;
use App\Support\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class PatrimonyController extends Controller
{
    public function index(Request $request)
    {
        $properties = Property::with('media')
            ->where('owner_id', $request->user()->id)
            ->where('is_private', true)
            ->latest()
            ->get();
        $shares = DB::table('asset_shares')
            ->join('users', 'users.id', '=', 'asset_shares.shared_with_id')
            ->whereIn('property_id', $properties->pluck('id'))
            ->whereNull('revoked_at')
            ->select('asset_shares.*', 'users.name as account_name')
            ->get()
            ->groupBy('property_id');
        $properties->each(
            fn (Property $property) => $property->setAttribute(
                'active_shares',
                $shares->get($property->id, collect())->values(),
            ),
        );

        return ApiResponse::success($properties);
    }

    public function sharedWithMe(Request $request)
    {
        $shares = DB::table('asset_shares')->where('shared_with_id', $request->user()->id)->whereNull('revoked_at')->get()->keyBy('property_id');
        $properties = Property::with(['media', 'owner:id,name,email'])->whereIn('id', $shares->keys())->get()->map(function ($property) use ($shares) {
            $share = $shares[$property->id];
            if ($share->permission === 'view') {
                $property->setRelation('media', $property->media->where('collection', 'gallery')->values());
            }$property->setAttribute('share_id', $share->id);
            $property->setAttribute('share_permission', $share->permission);

            return $property;
        });

        return ApiResponse::success($properties);
    }

    public function store(Request $request)
    {
        $data = $request->validate(['name' => 'required|string', 'type' => 'required|string', 'description' => 'nullable|string', 'surface' => 'nullable|numeric', 'address' => 'nullable|string', 'district' => 'nullable|string', 'commune' => 'nullable|string', 'cadastral_reference' => 'nullable|string', 'latitude' => 'nullable|numeric|between:-90,90', 'longitude' => 'nullable|numeric|between:-180,180', 'metadata' => 'nullable|array']);

        return ApiResponse::success(Property::create([...$data, 'owner_id' => $request->user()->id, 'is_private' => true]), 'Bien ajouté au coffre.', 201);
    }

    public function update(Request $request, Property $property)
    {
        $this->authorizeManagement($request, $property);
        $data = $request->validate([
            'name' => 'sometimes|required|string|max:180',
            'type' => 'sometimes|required|string|max:120',
            'description' => 'nullable|string|max:5000',
            'surface' => 'nullable|numeric|min:0',
            'address' => 'nullable|string|max:500',
            'district' => 'nullable|string|max:180',
            'commune' => 'nullable|string|max:180',
            'cadastral_reference' => 'nullable|string|max:180',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
            'metadata' => 'nullable|array',
        ]);
        $property->update($data);

        return ApiResponse::success($property->fresh('media'), 'Bien familial mis à jour.');
    }

    public function photos(Request $request, Property $property)
    {
        $this->authorizeContribution($request, $property);
        $data = $request->validate(['images' => 'required|array|min:1|max:20', 'images.*' => 'required|image|max:15360', 'labels' => 'required|string']);
        $labels = explode('|', $data['labels']);
        $media = [];
        foreach ($request->file('images', []) as $index => $image) {
            $media[] = Media::create(['user_id' => $request->user()->id, 'mediable_type' => Property::class, 'mediable_id' => $property->id, 'collection' => 'gallery', 'label' => $labels[$index] ?? 'Photo', 'disk' => 'private', 'path' => $image->store('vault/gallery', 'private'), 'mime_type' => $image->getMimeType(), 'size' => $image->getSize()]);
        }

        return ApiResponse::success($media, 'Galerie patrimoniale enregistrée.', 201);
    }

    public function document(Request $request, Property $property)
    {
        $this->authorizeContribution($request, $property);
        $data = $request->validate(['document' => 'required|file|mimes:pdf,jpg,jpeg,png|max:20480', 'label' => 'required|string|max:180']);
        $file = $request->file('document');
        $media = Media::create(['user_id' => $request->user()->id, 'mediable_type' => Property::class, 'mediable_id' => $property->id, 'collection' => 'documents', 'label' => $data['label'], 'disk' => 'private', 'path' => $file->store('vault/documents', 'private'), 'mime_type' => $file->getMimeType(), 'size' => $file->getSize(), 'metadata' => ['original_name' => $file->getClientOriginalName()]]);

        return ApiResponse::success($media, 'Document sécurisé.', 201);
    }

    public function download(Request $request, Media $media)
    {
        $this->authorizeMediaAccess($request, $media);
        abort_unless(Storage::disk($media->disk)->exists($media->path), 404, 'Fichier introuvable.');

        $downloadName = $media->metadata['original_name'] ?? basename($media->path);

        $content = Storage::disk($media->disk)->get($media->path);
        $safeName = str_replace(['"', "\r", "\n"], '', Str::ascii($downloadName));

        return response($content, 200, [
            'Content-Type' => $media->mime_type ?: 'application/octet-stream',
            'Content-Length' => (string) strlen($content),
            'Content-Disposition' => 'attachment; filename="'.$safeName.'"',
            'Cache-Control' => 'private, no-store, max-age=0',
        ]);
    }

    public function downloadChunk(Request $request, Media $media)
    {
        $this->authorizeMediaAccess($request, $media);
        $disk = Storage::disk($media->disk);
        abort_unless($disk->exists($media->path), 404, 'Fichier introuvable.');

        $offset = max(0, $request->integer('offset'));
        $chunkSize = 256 * 1024;
        $stream = $disk->readStream($media->path);
        abort_unless(is_resource($stream), 404, 'Fichier introuvable.');
        try {
            if ($offset > 0) {
                fseek($stream, $offset);
            }
            $bytes = fread($stream, $chunkSize) ?: '';
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

    public function shares(Request $request)
    {
        return ApiResponse::success(DB::table('asset_shares')->join('properties', 'properties.id', '=', 'asset_shares.property_id')->join('users', 'users.id', '=', 'asset_shares.shared_with_id')->where('properties.owner_id', $request->user()->id)->select('asset_shares.*', 'properties.name as property_name', 'users.name as account_name')->latest('asset_shares.created_at')->get());
    }

    public function share(Request $request, Property $property)
    {
        abort_unless($property->owner_id === $request->user()->id && $property->is_private, 403);
        $data = $request->validate(['name' => 'required|string|max:180', 'email' => 'required|email', 'permission' => 'required|in:view,documents,contribute,manage']);
        $email = Str::lower(trim($data['email']));
        $recipient = User::whereRaw('LOWER(email)=?', [$email])->first();
        abort_if($recipient && $recipient->role !== 'family_member', 422, 'Cette adresse appartient déjà à un autre espace VIMMO. Utilisez une autre adresse pour l’espace familial.');
        abort_if($recipient && $recipient->id === $request->user()->id, 422, 'Vous êtes déjà propriétaire de ce bien.');
        $permissionLabels = [
            'view' => 'consultation du bien',
            'documents' => 'consultation du bien et de ses documents',
            'contribute' => 'consultation et ajout de contenus',
            'manage' => 'gestion complète du bien partagé',
        ];
        $activationCode = null;
        $id = DB::transaction(function () use ($data, $property, &$recipient, $request, $permissionLabels, $email, &$activationCode): int {
            if (! $recipient) {
                $parts = preg_split('/\s+/', trim($data['name']), 2) ?: [];
                $recipient = User::create([
                    'name' => trim($data['name']),
                    'first_name' => $parts[0] ?? 'Membre',
                    'last_name' => $parts[1] ?? 'familial',
                    'email' => $email,
                    'role' => 'family_member',
                    'password' => Hash::make(Str::random(64)),
                    'is_active' => true,
                ]);
                $activationCode = (string) random_int(100000, 999999);
                DB::table('otp_codes')->insert([
                    'user_id' => $recipient->id,
                    'destination' => $recipient->email,
                    'purpose' => 'family_activation',
                    'code_hash' => Hash::make($activationCode),
                    'resend_count' => 0,
                    'last_sent_at' => now(),
                    'expires_at' => now()->addMinutes(10),
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            } elseif (! $recipient->is_active) {
                $recipient->forceFill(['is_active' => true])->save();
            }
            $existing = DB::table('asset_shares')->where(['property_id' => $property->id, 'shared_with_id' => $recipient->id])->first();
            $values = ['shared_by' => $request->user()->id, 'shared_with_id' => $recipient->id, 'name' => $data['name'], 'email' => $recipient->email, 'permission' => $data['permission'], 'revoked_at' => null, 'updated_at' => now()];
            if ($existing) {
                DB::table('asset_shares')->where('id', $existing->id)->update($values);
                $shareId = $existing->id;
            } else {
                $shareId = DB::table('asset_shares')->insertGetId([...$values, 'property_id' => $property->id, 'token' => (string) Str::uuid(), 'created_at' => now()]);
            }
            DB::table('notifications')->insert(['user_id' => $recipient->id, 'type' => 'patrimony_share', 'title' => 'Un bien est partagé avec vous', 'body' => $property->name.' est maintenant accessible dans votre espace familial.', 'data' => json_encode(['property_id' => $property->id, 'share_id' => $shareId]), 'created_at' => now(), 'updated_at' => now()]);
            Mail::to($recipient->email)->send(new PatrimonySharedMail(
                recipientName: $recipient->name,
                ownerName: $request->user()->name,
                propertyName: $property->name,
                permissionLabel: $permissionLabels[$data['permission']],
                activationCode: $activationCode,
                recipientEmail: $recipient->email,
            ));

            return $shareId;
        });

        return ApiResponse::success(DB::table('asset_shares')->find($id), 'Le bien est partagé avec '.$recipient->name.' et un e-mail lui a été envoyé.', 201);
    }

    public function revoke(Request $request, int $share)
    {
        $row = DB::table('asset_shares')->join('properties', 'properties.id', '=', 'asset_shares.property_id')->where('asset_shares.id', $share)->where('properties.owner_id', $request->user()->id)->first();
        abort_unless($row, 404);
        DB::table('asset_shares')->where('id', $share)->update(['revoked_at' => now(), 'updated_at' => now()]);
        $remainingShares = DB::table('asset_shares')->where('shared_with_id', $row->shared_with_id)->whereNull('revoked_at')->exists();
        if (! $remainingShares) {
            User::where('id', $row->shared_with_id)->where('role', 'family_member')->delete();
        }

        return ApiResponse::success(null, 'Accès révoqué.');
    }

    private function activeShare(Request $request, Property $property): ?object
    {
        return DB::table('asset_shares')->where(['property_id' => $property->id, 'shared_with_id' => $request->user()->id])->whereNull('revoked_at')->first();
    }

    private function authorizeMediaAccess(Request $request, Media $media): void
    {
        $allowed = false;
        if ($media->mediable instanceof Property) {
            $property = $media->mediable;
            if ($property->owner_id === $request->user()->id) {
                $allowed = true;
            } else {
                $share = $this->activeShare($request, $property);
                $allowed = $share && ($media->collection === 'gallery' || in_array($share->permission, ['documents', 'contribute', 'manage'], true));
            }
        } elseif ($media->mediable instanceof Message) {
            $allowed = $media->mediable->conversation->participants()->where('users.id', $request->user()->id)->exists();
        } elseif ($media->mediable instanceof MaintenanceRequest) {
            $allowed = $media->mediable->reported_by === $request->user()->id || $media->mediable->unit->property->owner_id === $request->user()->id;
        } elseif ($media->mediable instanceof InspectionItem) {
            $contract = $media->mediable->inspection->contract;
            $allowed = in_array($request->user()->id, [$contract->owner_id, $contract->tenant_id], true);
        }
        abort_unless($allowed, 403, 'Vous n’avez pas accès à ce fichier.');
    }

    private function authorizeContribution(Request $request, Property $property): void
    {
        if ($property->owner_id === $request->user()->id) {
            return;
        }$share = $this->activeShare($request, $property);
        abort_unless($share && in_array($share->permission, ['contribute', 'manage'], true), 403, 'Vous ne pouvez pas ajouter de contenu à ce bien.');
    }

    private function authorizeManagement(Request $request, Property $property): void
    {
        if ($property->owner_id === $request->user()->id) {
            return;
        }
        $share = $this->activeShare($request, $property);
        abort_unless(
            $share && $share->permission === 'manage',
            403,
            'Vous ne pouvez pas modifier ce bien.',
        );
    }
}
