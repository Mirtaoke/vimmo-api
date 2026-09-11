<?php

namespace Database\Seeders;

use App\Models\Listing;
use App\Models\RentalApplication;
use App\Models\User;
use Illuminate\Database\Seeder;

class RentalApplicationSeeder extends Seeder
{
    public function run(): void
    {
        $listing = Listing::firstOrFail();
        $seeker = User::where('role', 'seeker')->firstOrFail();
        RentalApplication::updateOrCreate(['listing_id' => $listing->id, 'applicant_id' => $seeker->id], ['message' => 'Je souhaite déposer mon dossier pour ce logement.', 'profile_data' => ['profession' => 'Consultante', 'revenu_mensuel' => 650000], 'status' => 'submitted']);
    }
}
