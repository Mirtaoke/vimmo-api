<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Listing;
use App\Models\RentalApplication;
use App\Support\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RentalApplicationController extends Controller
{
    public function index(Request $r)
    {
        $q = RentalApplication::with(['listing.unit.property', 'applicant:id,name,email,phone']);
        if ($r->user()->role === 'owner') {
            $q->whereHas('listing', fn ($x) => $x->where('owner_id', $r->user()->id));
        } else {
            $q->where('applicant_id', $r->user()->id);
        }if ($r->filled('status')) {
            $q->where('status', $r->status);
        }

return ApiResponse::success($q->latest()->get());
    }

    public function store(Request $r, Listing $listing)
    {
        abort_unless($listing->status === 'published', 422, 'Cette annonce n’accepte pas de candidature.');
        abort_if($listing->owner_id === $r->user()->id, 422, 'Vous ne pouvez pas candidater à votre propre annonce.');
        $d = $r->validate(['message' => 'nullable|string|max:2000', 'profile_data' => 'nullable|array']);
        $application = RentalApplication::updateOrCreate(['listing_id' => $listing->id, 'applicant_id' => $r->user()->id], [...$d, 'status' => 'submitted', 'owner_note' => null]);
        $this->notify($listing->owner_id, 'rental_application', 'Nouvelle candidature', 'Une candidature a été déposée pour '.$listing->title, ['application_id' => $application->id, 'listing_id' => $listing->id]);

        return ApiResponse::success($application->load(['listing', 'applicant']), 'Candidature envoyée.', 201);
    }

    public function status(Request $r, RentalApplication $application)
    {
        abort_unless($application->listing->owner_id === $r->user()->id, 403);
        $d = $r->validate(['status' => 'required|in:reviewing,accepted,rejected', 'owner_note' => 'nullable|string|max:2000']);
        $application->update($d);
        $this->notify($application->applicant_id, 'rental_application', 'Candidature mise à jour', 'Votre candidature pour '.$application->listing->title.' est maintenant : '.$d['status'], ['application_id' => $application->id]);

        return ApiResponse::success($application->fresh(['listing', 'applicant']), 'Statut de candidature mis à jour.');
    }

    public function withdraw(Request $r, RentalApplication $application)
    {
        abort_unless($application->applicant_id === $r->user()->id, 403);
        abort_if($application->status === 'accepted', 422, 'Une candidature acceptée ne peut plus être retirée.');
        $application->update(['status' => 'withdrawn']);

        return ApiResponse::success($application, 'Candidature retirée.');
    }

    private function notify(int $userId, string $type, string $title, string $body, array $data = []): void
    {
        DB::table('notifications')->insert(['user_id' => $userId, 'type' => $type, 'title' => $title, 'body' => $body, 'data' => json_encode($data), 'created_at' => now(), 'updated_at' => now()]);
    }
}
