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

class MarketplaceController extends Controller
{
    public function listings(Request $r)
    {
        $q = Listing::with(['unit.property.media', 'media', 'owner:id,name,phone'])->where('status', 'published');
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
        foreach (['furnished', 'parking', 'water', 'electricity', 'air_conditioning', 'security', 'pool', 'terrace'] as $amenity) {
            if ($r->boolean($amenity)) {
                $q->whereHas('unit', fn ($x) => $x->whereJsonContains('amenities', $amenity));
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

        return ApiResponse::success($q->latest('published_at')->paginate(15));
    }

    public function show(Listing $listing)
    {
        abort_unless($listing->status === 'published', 404);

        return ApiResponse::success($listing->load(['unit.property.media', 'owner:id,name,phone', 'media']));
    }

    public function properties(Request $r)
    {
        return ApiResponse::success(Property::with(['units', 'media'])->where('owner_id', $r->user()->id)->latest()->get());
    }

    public function units(Request $r)
    {
        $q = Unit::with(['property.media', 'contracts.tenant:id,name,email,phone'])->whereHas('property', fn ($x) => $x->where('owner_id', $r->user()->id));
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
        return ApiResponse::success(Listing::with(['unit.property.media', 'media'])->where('owner_id', $r->user()->id)->latest()->get());
    }

    public function storeProperty(Request $r)
    {
        $d = $r->validate(['name' => 'required|string', 'type' => 'required|string', 'description' => 'nullable|string', 'address' => 'nullable|string', 'district' => 'nullable|string', 'commune' => 'nullable|string', 'city' => 'nullable|string', 'surface' => 'nullable|numeric|min:0', 'latitude' => 'nullable|numeric|between:-90,90', 'longitude' => 'nullable|numeric|between:-180,180', 'is_private' => 'boolean']);

        return ApiResponse::success(Property::create([...$d, 'owner_id' => $r->user()->id]), 'Bien créé.', 201);
    }

    public function updateProperty(Request $r, Property $property)
    {
        abort_unless($property->owner_id === $r->user()->id, 403);
        $d = $r->validate(['name' => 'sometimes|required|string', 'type' => 'sometimes|required|string', 'description' => 'nullable|string', 'address' => 'nullable|string', 'district' => 'nullable|string', 'commune' => 'nullable|string', 'city' => 'nullable|string', 'surface' => 'nullable|numeric|min:0', 'latitude' => 'nullable|numeric|between:-90,90', 'longitude' => 'nullable|numeric|between:-180,180', 'is_private' => 'boolean']);
        $property->update($d);

        return ApiResponse::success($property->fresh(['units', 'media']), 'Bien mis à jour.');
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
            $media[] = Media::create(['user_id' => $r->user()->id, 'mediable_type' => Property::class, 'mediable_id' => $property->id, 'collection' => str_starts_with((string) $file->getMimeType(), 'video/') ? 'videos' : 'gallery', 'label' => $labels[$index] ?? 'Pièce', 'disk' => 'public', 'path' => $file->store('properties', 'public'), 'mime_type' => $file->getMimeType(), 'size' => $file->getSize()]);
        }

return ApiResponse::success($media, 'Galerie du bien enregistrée.', 201);
    }

    public function storeUnit(Request $r, Property $property)
    {
        abort_unless($property->owner_id === $r->user()->id, 403);
        $d = $r->validate(['reference' => 'required|string', 'type' => 'required|string', 'surface' => 'nullable|numeric', 'rooms' => 'integer|min:0', 'bedrooms' => 'integer|min:0', 'bathrooms' => 'integer|min:0', 'monthly_rent' => 'numeric|min:0', 'amenities' => 'nullable|array']);

        return ApiResponse::success($property->units()->create($d), 'Logement créé.', 201);
    }

    public function storeListing(Request $r, ListingAlertService $alerts)
    {
        $d = $r->validate(['unit_id' => 'required|exists:units,id', 'title' => 'required|string|max:180', 'description' => 'required|string', 'price' => 'required|numeric|min:0', 'deposit' => 'nullable|numeric|min:0', 'charges' => 'nullable|numeric|min:0', 'available_from' => 'nullable|date', 'status' => 'nullable|in:draft,pending,published,reserved,rented,suspended,archived']);
        $unit = Unit::with('property')->findOrFail($d['unit_id']);
        abort_unless($unit->property->owner_id === $r->user()->id, 403);
        abort_if($unit->property->is_private, 422, 'Un bien patrimonial privé ne peut pas être publié.');
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
        $d = $r->validate(['title' => 'sometimes|required|string|max:180', 'description' => 'sometimes|required|string', 'price' => 'sometimes|required|numeric|min:0', 'deposit' => 'nullable|numeric|min:0', 'charges' => 'nullable|numeric|min:0', 'available_from' => 'nullable|date', 'status' => 'sometimes|required|in:draft,pending,published,reserved,rented,suspended,archived']);
        $becomesPublished = ($d['status'] ?? null) === 'published' && $listing->status !== 'published';
        if ($becomesPublished && ! $listing->published_at) {
            $d['published_at'] = now();
        }$listing->update($d);
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
        return ApiResponse::success(Listing::with('unit.property')->whereIn('id', DB::table('favorites')->where('user_id', $r->user()->id)->pluck('listing_id'))->get());
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

    public function visit(Request $r, Listing $listing)
    {
        abort_unless($listing->status === 'published', 422, 'Cette annonce n’accepte pas de visite.');
        $d = $r->validate(['requested_at' => 'required|date|after:now', 'comment' => 'nullable|string']);
        $id = DB::table('visit_requests')->insertGetId([...$d, 'listing_id' => $listing->id, 'requester_id' => $r->user()->id, 'status' => 'requested', 'created_at' => now(), 'updated_at' => now()]);
        DB::table('notifications')->insert(['user_id' => $listing->owner_id, 'type' => 'visit', 'title' => 'Nouvelle demande de visite', 'body' => 'Une visite est demandée pour '.$listing->title.'.', 'data' => json_encode(['visit_id' => $id, 'listing_id' => $listing->id]), 'created_at' => now(), 'updated_at' => now()]);

        return ApiResponse::success(DB::table('visit_requests')->find($id), 'Demande de visite envoyée.', 201);
    }

    public function visits(Request $r)
    {
        $q = DB::table('visit_requests')->join('listings', 'listings.id', '=', 'visit_requests.listing_id');
        if ($r->user()->role === 'owner') {
            $q->where('listings.owner_id', $r->user()->id);
        } else {
            $q->where('visit_requests.requester_id', $r->user()->id);
        }

return ApiResponse::success($q->select('visit_requests.*', 'listings.title')->latest('visit_requests.created_at')->get());
    }

    public function visitStatus(Request $r, int $visit)
    {
        $row = DB::table('visit_requests')->join('listings', 'listings.id', '=', 'visit_requests.listing_id')->where('visit_requests.id', $visit)->where('listings.owner_id', $r->user()->id)->select('visit_requests.*', 'listings.title')->first();
        abort_unless($row,404);
        $d = $r->validate(['status' => 'required|in:accepted,confirmed,completed,cancelled']);
        DB::table('visit_requests')->where('id',$visit)->update(['status' => $d['status'], 'updated_at' => now()]);
        DB::table('notifications')->insert(['user_id' => $row->requester_id, 'type' => 'visit', 'title' => 'Visite mise à jour', 'body' => 'Votre visite pour '.$row->title.' est maintenant : '.$d['status'].'.', 'data' => json_encode(['visit_id' => $visit]), 'created_at' => now(), 'updated_at' => now()]);

        return ApiResponse::success(DB::table('visit_requests')->find($visit),'Statut de visite mis à jour.');
    }
}
