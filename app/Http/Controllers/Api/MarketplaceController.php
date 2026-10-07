<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\LeaseContract;
use App\Models\Listing;
use App\Models\Media;
use App\Models\Property;
use App\Models\Unit;
use App\Services\ListingAlertService;
use App\Support\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class MarketplaceController extends Controller
{
    public function viewMedia(Media $media)
    {
        abort_unless(
            $media->disk === 'public' &&
                in_array($media->collection, ['gallery', 'photos'], true) &&
                str_starts_with((string) $media->mime_type, 'image/'),
            404,
        );
        $disk = Storage::disk('public');
        abort_unless($disk->exists($media->path), 404, 'Image introuvable.');

        return response($disk->get($media->path), 200, [
            'Content-Type' => $media->mime_type ?: 'image/jpeg',
            'Content-Length' => (string) $disk->size($media->path),
            'Content-Disposition' => 'inline',
            'Cache-Control' => 'private, max-age=21600',
        ]);
    }

    public function listings(Request $r)
    {
        $q = Listing::with(['unit.media', 'unit.property.media', 'media', 'owner:id,name,phone'])
            ->where('status', 'published')
            ->whereHas('unit', fn ($unit) => $unit->where('status', 'available'));
        if ($r->filled('type')) {
            $types = collect(explode(',', $r->type))->map(fn ($type) => strtolower(trim($type)))->filter()->values();
            $q->whereHas('unit', fn ($unit) => $unit->whereIn(DB::raw('LOWER(type)'), $types));
        }
        if ($r->filled('city')) {
            $q->whereHas('unit.property', fn ($x) => $x->where('city', 'like', '%'.$r->city.'%'));
        }
        foreach (['commune', 'district'] as $field) {
            if ($r->filled($field)) {
                $q->whereHas('unit.property', fn ($x) => $x->where($field, 'like', '%'.$r->$field.'%'));
            }
        }
        if ($r->filled('zone')) {
            $zone = '%'.$r->zone.'%';
            $q->whereHas('unit.property', fn ($x) => $x->where(fn ($p) => $p->where('district', 'like', $zone)->orWhere('commune', 'like', $zone)->orWhere('city', 'like', $zone)));
        }
        if ($r->filled('q')) {
            $term = '%'.$r->q.'%';
            $q->where(function ($query) use ($term) {
                $query->where('title', 'like', $term)->orWhere('description', 'like', $term)
                    ->orWhereHas('unit', fn ($unit) => $unit->where('type', 'like', $term)->orWhereHas('property', fn ($property) => $property->where('name', 'like', $term)->orWhere('address', 'like', $term)->orWhere('district', 'like', $term)->orWhere('commune', 'like', $term)->orWhere('city', 'like', $term)));
            });
        }
        if ($r->filled('min_price')) {
            $q->where('price', '>=', $r->min_price);
        }
        if ($r->filled('max_price')) {
            $q->where('price', '<=', $r->max_price);
        }
        if ($r->filled('bedrooms')) {
            $q->whereHas('unit', fn ($x) => $x->where('bedrooms', '>=', $r->bedrooms));
        }
        if ($r->filled('rooms')) {
            $q->whereHas('unit', fn ($x) => $x->where('rooms', '>=', $r->rooms));
        }
        if ($r->filled('min_surface')) {
            $q->whereHas('unit', fn ($x) => $x->where('surface', '>=', $r->min_surface));
        }
        if ($r->filled('max_surface')) {
            $q->whereHas('unit', fn ($x) => $x->where('surface', '<=', $r->max_surface));
        }
        $amenityAliases = [
            'furnished' => ['furnished', 'meuble', 'meublé'],
            'parking' => ['parking'],
            'water' => ['water', 'eau'],
            'electricity' => ['electricity', 'électricité', 'electricite'],
            'air_conditioning' => ['air_conditioning', 'climatisation'],
            'security' => ['security', 'sécurité', 'securite'],
            'pool' => ['pool', 'piscine'],
            'terrace' => ['terrace', 'terrasse'],
        ];
        foreach ($amenityAliases as $filter => $aliases) {
            if ($r->boolean($filter)) {
                $q->whereHas('unit', function ($unit) use ($aliases) {
                    $unit->where(function ($amenities) use ($aliases) {
                        foreach ($aliases as $index => $alias) {
                            $method = $index === 0 ? 'whereJsonContains' : 'orWhereJsonContains';
                            $amenities->{$method}('amenities', $alias);
                        }
                    });
                });
            }
        }
        if ($r->filled('availability')) {
            $statuses = collect(explode(',', $r->string('availability')->toString()))
                ->map(fn (string $status): string => trim($status))
                ->filter(fn (string $status): bool => in_array($status, ['available', 'reserved', 'maintenance', 'inspection', 'inactive'], true))
                ->values();
            if ($statuses->isNotEmpty()) {
                $q->whereHas('unit', fn ($unit) => $unit->whereIn('status', $statuses));
            }
        }
        if ($r->filled('available_from')) {
            $q->where(fn ($x) => $x->whereNull('available_from')->orWhereDate('available_from', '<=', $r->available_from));
        }
        if ($r->filled(['latitude', 'longitude'])) {
            $latitude = (float) $r->latitude;
            $longitude = (float) $r->longitude;
            $radius = max(1, min(200, (float) $r->input('radius_km', 25)));
            $latitudeDelta = $radius / 111.0;
            $longitudeDelta = $radius / (111.0 * max(0.1, cos(deg2rad($latitude))));
            $q->whereHas('unit.property', fn ($property) => $property->whereNotNull('latitude')->whereNotNull('longitude')->whereBetween('latitude', [$latitude - $latitudeDelta, $latitude + $latitudeDelta])->whereBetween('longitude', [$longitude - $longitudeDelta, $longitude + $longitudeDelta]));
        }

        $perPage = max(1, min(50, $r->integer('per_page', 15)));

        return ApiResponse::success($q->latest('published_at')->paginate($perPage));
    }

    public function show(Listing $listing)
    {
        abort_unless($listing->status === 'published', 404);
        abort_unless($listing->unit()->where('status', 'available')->exists(), 404, 'Ce logement n’est plus disponible.');

        return ApiResponse::success($listing->load(['unit.media', 'unit.property.media', 'owner:id,name,phone', 'media']));
    }

    public function properties(Request $r)
    {
        return ApiResponse::success(Property::with(['units.media', 'media'])
            ->where('owner_id', $r->user()->id)
            ->latest()
            ->get());
    }

    public function units(Request $r)
    {
        $q = Unit::with(['media', 'property.media', 'contracts.tenant:id,name,email,phone'])->whereHas('property', fn ($x) => $x->where('owner_id', $r->user()->id));
        if ($r->filled('property_id')) {
            $q->where('property_id', $r->integer('property_id'));
        }if ($r->filled('status')) {
            $q->where('status', $r->status);
        }

        return ApiResponse::success($q->get());
    }

    public function tenants(Request $r)
    {
        $rows = LeaseContract::with(['tenant:id,name,email,phone', 'unit.property', 'schedules'])->where('owner_id', $r->user()->id)->when($r->filled('property_id'), fn ($q) => $q->whereHas('unit', fn ($u) => $u->where('property_id', $r->integer('property_id'))))->latest()->get();

        return ApiResponse::success($rows);
    }

    public function ownerListings(Request $r)
    {
        return ApiResponse::success(Listing::with(['unit.media', 'unit.property.media', 'media'])->where('owner_id', $r->user()->id)->latest()->get());
    }

    public function storeProperty(Request $r)
    {
        $d = $r->validate(
            ['name' => 'required|string', 'type' => 'required|string', 'description' => 'nullable|string', 'address' => 'nullable|string', 'district' => 'nullable|string', 'commune' => 'nullable|string', 'city' => 'nullable|string', 'surface' => 'nullable|numeric|min:0', 'latitude' => 'nullable|numeric|between:-90,90', 'longitude' => 'nullable|numeric|between:-180,180', 'is_private' => 'boolean'],
            $this->propertyMessages(),
            $this->propertyAttributes(),
        );

        return ApiResponse::success(Property::create([...$d, 'owner_id' => $r->user()->id]), 'Bien créé.', 201);
    }

    public function updateProperty(Request $r, Property $property)
    {
        abort_unless($property->owner_id === $r->user()->id, 403);
        $d = $r->validate(
            ['name' => 'sometimes|required|string', 'type' => 'sometimes|required|string', 'description' => 'nullable|string', 'address' => 'nullable|string', 'district' => 'nullable|string', 'commune' => 'nullable|string', 'city' => 'nullable|string', 'surface' => 'nullable|numeric|min:0', 'latitude' => 'nullable|numeric|between:-90,90', 'longitude' => 'nullable|numeric|between:-180,180', 'is_private' => 'boolean'],
            $this->propertyMessages(),
            $this->propertyAttributes(),
        );
        if (($d['is_private'] ?? false) && ! $property->is_private) {
            abort_if(
                $property->units()->whereHas('contracts', fn ($query) => $query->where('status', 'active'))->exists(),
                422,
                'Un bien avec un contrat locatif actif ne peut pas devenir familial.',
            );
        }
        $property->update($d);

        return ApiResponse::success($property->fresh(['units.media', 'media']), 'Bien mis à jour.');
    }

    public function deleteProperty(Request $r, Property $property)
    {
        abort_unless($property->owner_id === $r->user()->id, 403);
        abort_if($property->units()->whereHas('contracts', fn ($q) => $q->where('status', 'active'))->exists(), 422, 'Impossible de supprimer un bien lié à un contrat actif.');
        $property->delete();

        return ApiResponse::success(null, 'Bien supprimé.');
    }

    public function storePropertyMedia(Request $r, Property $property)
    {
        abort_unless($property->owner_id === $r->user()->id, 403);
        $data = $r->validate(['files' => 'required_without:images|array|min:1|max:20', 'files.*' => 'file|mimes:jpg,jpeg,png,webp,mp4,mov,webm|max:30720', 'images' => 'required_without:files|array|min:1|max:20', 'images.*' => 'image|max:15360', 'labels' => 'required|string']);
        $labels = explode('|', $data['labels']);
        $files = $r->file('files', $r->file('images', []));
        $media = [];
        foreach ($files as $index => $file) {
            $storedPath = $file->store('properties', 'public');
            abort_if(
                ! is_string($storedPath) || $storedPath === '',
                500,
                'La photo n’a pas pu être enregistrée sur le serveur. Vérifiez les droits du dossier storage/app/public.',
            );
            $media[] = Media::create(['user_id' => $r->user()->id, 'mediable_type' => Property::class, 'mediable_id' => $property->id, 'collection' => str_starts_with((string) $file->getMimeType(), 'video/') ? 'videos' : 'gallery', 'label' => $labels[$index] ?? 'Pièce', 'disk' => 'public', 'path' => $storedPath, 'mime_type' => $file->getMimeType(), 'size' => $file->getSize()]);
        }

        return ApiResponse::success($media, 'Galerie du bien enregistrée.', 201);
    }

    public function storeUnit(Request $r, Property $property)
    {
        abort_unless($property->owner_id === $r->user()->id, 403);
        $d = $r->validate(
            [
                'reference' => 'required|string',
                'type' => 'required|string',
                'description' => 'nullable|string',
                'surface' => 'nullable|numeric',
                'rooms' => 'integer|min:0',
                'bedrooms' => 'integer|min:0',
                'bathrooms' => 'integer|min:0',
                'monthly_rent' => $property->is_private ? 'nullable|numeric|min:0' : 'required|numeric|min:1',
                'monthly_charges' => 'nullable|numeric|min:0',
                'deposit_amount' => 'nullable|numeric|min:0',
                'advance_months' => 'nullable|integer|min:0|max:24',
                'charges_description' => 'nullable|string|max:1000',
                'deposit_description' => 'nullable|string|max:1000',
                'amenities' => 'nullable|array',
                'amenity_details' => 'nullable|array',
                'amenity_details.*' => 'nullable|string|max:1000',
            ],
            $this->unitMessages(),
            $this->unitAttributes(),
        );

        return ApiResponse::success($property->units()->create($d), 'Logement créé.', 201);
    }

    public function updateUnit(Request $r, Unit $unit)
    {
        abort_unless($unit->property()->where('owner_id', $r->user()->id)->exists(), 403);
        $unit->loadMissing('property');
        $data = $r->validate([
            'reference' => 'sometimes|required|string|max:120',
            'type' => 'sometimes|required|string|max:120',
            'description' => 'nullable|string|max:5000',
            'surface' => 'nullable|numeric|min:0',
            'rooms' => 'sometimes|integer|min:0',
            'bedrooms' => 'sometimes|integer|min:0',
            'bathrooms' => 'sometimes|integer|min:0',
            'monthly_rent' => $unit->property->is_private
                ? 'sometimes|nullable|numeric|min:0'
                : 'sometimes|required|numeric|min:1',
            'monthly_charges' => 'nullable|numeric|min:0',
            'deposit_amount' => 'nullable|numeric|min:0',
            'advance_months' => 'nullable|integer|min:0|max:24',
            'charges_description' => 'nullable|string|max:1000',
            'deposit_description' => 'nullable|string|max:1000',
            'amenities' => 'nullable|array',
            'amenity_details' => 'nullable|array',
            'amenity_details.*' => 'nullable|string|max:1000',
            'status' => 'sometimes|required|in:available,reserved,maintenance,inspection,inactive',
        ], $this->unitMessages(), $this->unitAttributes());
        if (isset($data['reference'])) {
            abort_if(
                Unit::where('property_id', $unit->property_id)
                    ->where('reference', $data['reference'])
                    ->whereKeyNot($unit->id)
                    ->exists(),
                422,
                'Cette référence est déjà utilisée dans ce bien.',
            );
        }
        abort_if(
            isset($data['status']) &&
                $unit->contracts()->where('status', 'active')->exists(),
            422,
            'Le statut d’un logement occupé dépend de son contrat actif.',
        );
        $unit->update($data);

        return ApiResponse::success($unit->fresh('media'), 'Logement mis à jour.');
    }

    public function deleteUnit(Request $r, Unit $unit)
    {
        abort_unless($unit->property()->where('owner_id', $r->user()->id)->exists(), 403);
        abort_if(
            $unit->contracts()->where('status', 'active')->exists(),
            422,
            'Impossible de supprimer un logement lié à un contrat actif.',
        );
        $unit->delete();

        return ApiResponse::success(null, 'Logement supprimé.');
    }

    public function storeUnitMedia(Request $r, Unit $unit)
    {
        abort_unless($unit->property()->where('owner_id', $r->user()->id)->exists(), 403);
        $data = $r->validate([
            'images' => 'required|array|min:1|max:20',
            'images.*' => 'image|max:15360',
            'labels' => 'required|string',
        ]);
        $labels = explode('|', $data['labels']);
        $media = [];
        foreach ($r->file('images', []) as $index => $file) {
            $storedPath = $file->store('units', 'public');
            abort_if(
                ! is_string($storedPath) || $storedPath === '',
                500,
                'La photo n’a pas pu être enregistrée sur le serveur. Vérifiez les droits du dossier storage/app/public.',
            );
            $media[] = Media::create([
                'user_id' => $r->user()->id,
                'mediable_type' => Unit::class,
                'mediable_id' => $unit->id,
                'collection' => 'gallery',
                'label' => $labels[$index] ?? 'Pièce',
                'disk' => 'public',
                'path' => $storedPath,
                'mime_type' => $file->getMimeType(),
                'size' => $file->getSize(),
            ]);
        }

        return ApiResponse::success($media, 'Galerie du logement enregistrée.', 201);
    }

    public function deleteUnitMedia(Request $r, Unit $unit, Media $media)
    {
        abort_unless($unit->property()->where('owner_id', $r->user()->id)->exists(), 403);
        abort_unless(
            $media->mediable_type === Unit::class && $media->mediable_id === $unit->id,
            404,
        );
        $media->delete();

        return ApiResponse::success(null, 'Photo supprimée du logement.');
    }

    public function storeListing(Request $r, ListingAlertService $alerts)
    {
        $d = $r->validate([
            'unit_id' => 'required|exists:units,id',
            'title' => 'required|string|max:180',
            'description' => 'required|string',
            'price' => 'required|numeric|min:1',
            'deposit' => 'nullable|numeric|min:0',
            'charges' => 'nullable|numeric|min:0',
            'advance_amount' => 'nullable|numeric|min:0',
            'charges_description' => 'nullable|string|max:1000',
            'deposit_description' => 'nullable|string|max:1000',
            'available_from' => 'nullable|date',
            'status' => 'nullable|in:draft,pending,published,reserved,rented,suspended,archived',
        ]);
        $unit = Unit::with('property')->findOrFail($d['unit_id']);
        abort_unless($unit->property->owner_id === $r->user()->id, 403);
        abort_if($unit->property->is_private, 422, 'Un bien patrimonial privé ne peut pas être publié.');
        abort_unless($unit->status === 'available', 422, 'Seul un logement disponible peut être publié.');
        $status = $d['status'] ?? 'draft';
        $listing = Listing::create([...$d, 'owner_id' => $r->user()->id, 'status' => $status, 'published_at' => $status === 'published' ? now() : null]);
        if ($status === 'published') {
            $alerts->notifyFor($listing);
        }

        return ApiResponse::success($listing, 'Annonce enregistrée.', 201);
    }

    public function updateListing(Request $r, Listing $listing, ListingAlertService $alerts)
    {
        abort_unless($listing->owner_id === $r->user()->id, 403);
        $d = $r->validate([
            'title' => 'sometimes|required|string|max:180',
            'description' => 'sometimes|required|string',
            'price' => 'sometimes|required|numeric|min:1',
            'deposit' => 'nullable|numeric|min:0',
            'charges' => 'nullable|numeric|min:0',
            'advance_amount' => 'nullable|numeric|min:0',
            'charges_description' => 'nullable|string|max:1000',
            'deposit_description' => 'nullable|string|max:1000',
            'available_from' => 'nullable|date',
            'status' => 'sometimes|required|in:draft,pending,published,reserved,rented,suspended,archived',
        ]);
        if (($d['status'] ?? null) === 'published') {
            abort_unless(
                $listing->unit()->where('status', 'available')->exists(),
                422,
                'Ce logement est déjà loué et ne peut pas être republié.',
            );
        }
        $becomesPublished = ($d['status'] ?? null) === 'published' && $listing->status !== 'published';
        if ($becomesPublished && ! $listing->published_at) {
            $d['published_at'] = now();
        }
        $listing->update($d);
        if ($becomesPublished) {
            $alerts->notifyFor($listing);
        }

        return ApiResponse::success($listing->fresh(['unit.property', 'media']), 'Annonce mise à jour.');
    }

    public function deleteListing(Request $r, Listing $listing)
    {
        abort_unless($listing->owner_id === $r->user()->id, 403);
        $listing->delete();

        return ApiResponse::success(null, 'Annonce supprimée.');
    }

    public function favorite(Request $r, Listing $listing)
    {
        abort_unless($listing->status === 'published', 422, 'Cette annonce n’est plus disponible.');
        abort_unless($listing->unit()->where('status', 'available')->exists(), 422, 'Ce logement est déjà loué.');
        DB::table('favorites')->updateOrInsert(['user_id' => $r->user()->id, 'listing_id' => $listing->id], ['created_at' => now(), 'updated_at' => now()]);

        return ApiResponse::success(null, 'Ajouté aux favoris.');
    }

    public function unfavorite(Request $r, Listing $listing)
    {
        DB::table('favorites')->where(['user_id' => $r->user()->id, 'listing_id' => $listing->id])->delete();

        return ApiResponse::success(null, 'Retiré des favoris.');
    }

    public function favorites(Request $r)
    {
        return ApiResponse::success(Listing::with(['unit.media', 'unit.property.media', 'media', 'owner:id,name,phone'])
            ->whereIn('id', DB::table('favorites')->where('user_id', $r->user()->id)->pluck('listing_id'))
            ->where('status', 'published')
            ->whereHas('unit', fn ($unit) => $unit->where('status', 'available'))
            ->latest('published_at')
            ->get());
    }

    public function savedSearches(Request $r)
    {
        return ApiResponse::success(DB::table('saved_searches')->where('user_id', $r->user()->id)->latest()->get());
    }

    public function saveSearch(Request $r)
    {
        $d = $r->validate(['name' => 'required|string', 'criteria' => 'required|array', 'alerts_enabled' => 'boolean']);
        $id = DB::table('saved_searches')->insertGetId([...$d, 'criteria' => json_encode($d['criteria']), 'user_id' => $r->user()->id, 'created_at' => now(), 'updated_at' => now()]);

        return ApiResponse::success(DB::table('saved_searches')->find($id), 'Recherche sauvegardée.', 201);
    }

    public function deleteSearch(Request $r, int $search)
    {
        $deleted = DB::table('saved_searches')->where(['id' => $search, 'user_id' => $r->user()->id])->delete();
        abort_unless($deleted, 404);

        return ApiResponse::success(null, 'Recherche supprimée.');
    }

    public function updateSearch(Request $r, int $search)
    {
        $data = $r->validate([
            'name' => 'sometimes|required|string|max:180',
            'alerts_enabled' => 'sometimes|required|boolean',
        ]);
        abort_if($data === [], 422, 'Aucune modification à enregistrer.');
        $query = DB::table('saved_searches')
            ->where(['id' => $search, 'user_id' => $r->user()->id]);
        abort_unless($query->exists(), 404, 'Recherche sauvegardée introuvable.');
        $query->update([...$data, 'updated_at' => now()]);

        return ApiResponse::success(
            DB::table('saved_searches')->find($search),
            'Recherche mise à jour.',
        );
    }

    public function visit(Request $r, Listing $listing)
    {
        abort_unless($listing->status === 'published', 422, 'Cette annonce n’accepte pas de visite.');
        abort_unless($listing->unit()->where('status', 'available')->exists(), 422, 'Ce logement est déjà loué.');
        $d = $r->validate(['requested_at' => 'required|date|after:now', 'comment' => 'nullable|string']);
        $id = DB::table('visit_requests')->insertGetId([...$d, 'listing_id' => $listing->id, 'requester_id' => $r->user()->id, 'status' => 'requested', 'created_at' => now(), 'updated_at' => now()]);
        DB::table('notifications')->insert(['user_id' => $listing->owner_id, 'type' => 'visit', 'title' => 'Nouvelle demande de visite', 'body' => 'Une visite est demandée pour '.$listing->title.'.', 'data' => json_encode(['visit_id' => $id, 'listing_id' => $listing->id]), 'created_at' => now(), 'updated_at' => now()]);

        return ApiResponse::success(DB::table('visit_requests')->find($id), 'Demande de visite envoyée.', 201);
    }

    public function visits(Request $r)
    {
        $q = DB::table('visit_requests')
            ->join('listings', 'listings.id', '=', 'visit_requests.listing_id')
            ->leftJoin('users as requesters', 'requesters.id', '=', 'visit_requests.requester_id');
        if ($r->user()->role === 'owner') {
            $q->where('listings.owner_id', $r->user()->id);
        } else {
            $q->where('visit_requests.requester_id', $r->user()->id);
        }

        return ApiResponse::success($q->select(
            'visit_requests.*',
            'listings.title',
            'requesters.name as requester_name',
            'requesters.email as requester_email',
            'requesters.phone as requester_phone',
        )->latest('visit_requests.created_at')->get());
    }

    public function visitStatus(Request $r, int $visit)
    {
        $row = DB::table('visit_requests')->join('listings', 'listings.id', '=', 'visit_requests.listing_id')->where('visit_requests.id', $visit)->where('listings.owner_id', $r->user()->id)->select('visit_requests.*', 'listings.title')->first();
        abort_unless($row, 404);
        $d = $r->validate([
            'status' => 'required|in:accepted,confirmed,completed,cancelled',
            'owner_note' => 'nullable|string|max:2000',
            'proposed_at' => 'nullable|date|after:now',
            'rejection_reason' => 'required_if:status,cancelled|nullable|string|max:2000',
        ], [
            'rejection_reason.required_if' => 'Le motif du refus est requis.',
            'proposed_at.after' => 'Le nouvel horaire doit être à venir.',
        ]);
        $update = [
            ...$d,
            'owner_note' => $d['owner_note'] ?? null,
            'proposed_at' => in_array($d['status'], ['accepted', 'confirmed'], true) ? ($d['proposed_at'] ?? null) : null,
            'rejection_reason' => $d['status'] === 'cancelled' ? $d['rejection_reason'] : null,
            'updated_at' => now(),
        ];
        DB::table('visit_requests')->where('id', $visit)->update($update);
        $statusLabel = match ($d['status']) {
            'accepted', 'confirmed' => 'confirmée',
            'completed' => 'terminée',
            'cancelled' => 'refusée',
        };
        $detail = $d['status'] === 'cancelled'
            ? ' Motif : '.$d['rejection_reason']
            : (isset($d['proposed_at']) ? ' Nouveau créneau proposé : '.$d['proposed_at'].'.' : '');
        DB::table('notifications')->insert(['user_id' => $row->requester_id, 'type' => 'visit', 'title' => 'Visite mise à jour', 'body' => 'Votre visite pour '.$row->title.' est '.$statusLabel.'.'.$detail, 'data' => json_encode(['visit_id' => $visit]), 'created_at' => now(), 'updated_at' => now()]);

        return ApiResponse::success(DB::table('visit_requests')->find($visit), 'Statut de visite mis à jour.');
    }

    private function propertyAttributes(): array
    {
        return [
            'name' => 'nom du bien',
            'type' => 'type de bien',
            'description' => 'description',
            'address' => 'adresse',
            'district' => 'quartier',
            'commune' => 'commune',
            'city' => 'ville',
            'surface' => 'surface',
            'latitude' => 'latitude',
            'longitude' => 'longitude',
            'is_private' => 'caractère privé du bien',
        ];
    }

    private function propertyMessages(): array
    {
        return [
            'name.required' => 'Le nom du bien est requis.',
            'type.required' => 'Le type de bien est requis.',
            'surface.numeric' => 'La surface doit être un nombre valide.',
            'latitude.numeric' => 'La position GPS est invalide.',
            'longitude.numeric' => 'La position GPS est invalide.',
        ];
    }

    private function unitAttributes(): array
    {
        return [
            'reference' => 'référence du logement',
            'type' => 'type de logement',
            'description' => 'description du logement',
            'surface' => 'surface du logement',
            'rooms' => 'nombre de pièces',
            'bedrooms' => 'nombre de chambres',
            'bathrooms' => 'nombre de salles de bain',
            'monthly_rent' => 'loyer mensuel',
            'monthly_charges' => 'charges mensuelles',
            'deposit_amount' => 'caution',
            'advance_months' => 'nombre de mois prépayés',
            'charges_description' => 'détail des charges',
            'deposit_description' => 'détail de la caution',
            'amenities' => 'équipements',
            'amenity_details' => 'détails des équipements',
            'status' => 'statut du logement',
        ];
    }

    private function unitMessages(): array
    {
        return [
            'reference.required' => 'La référence du logement est requise.',
            'type.required' => 'Le type de logement est requis.',
            'surface.numeric' => 'La surface du logement doit être un nombre valide.',
            'rooms.integer' => 'Le nombre de pièces doit être un entier.',
            'bedrooms.integer' => 'Le nombre de chambres doit être un entier.',
            'bathrooms.integer' => 'Le nombre de salles de bain doit être un entier.',
            'monthly_rent.numeric' => 'Le loyer mensuel doit être un nombre valide.',
        ];
    }
}
