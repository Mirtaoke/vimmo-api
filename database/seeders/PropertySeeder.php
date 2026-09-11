<?php

namespace Database\Seeders;

use App\Models\Property;
use App\Models\User;
use Illuminate\Database\Seeder;

class PropertySeeder extends Seeder
{
    public function run(): void
    {
        $rows = [
            ['proprietaire@vimmo.bj', 'Villa Azur', 'Villa', 'Route des Pêches', 'Fidjrossè', 'Cotonou', 180, false, 6.3540, 2.3650],
            ['proprietaire@vimmo.bj', 'Penthouse Naya', 'Appartement', 'Rue 2350', 'Haie Vive', 'Cotonou', 142, false, 6.3610, 2.4000],
            ['proprietaire@vimmo.bj', 'Maison Kora', 'Maison', 'Quartier Zomaï', 'Zomaï', 'Ouidah', 210, false, 6.3630, 2.0860],
            ['proprietaire@vimmo.bj', 'Parcelle Agblangandan', 'Parcelle', 'RNIE 1', 'Agblangandan', 'Sèmè-Podji', 1240, true, 6.3860, 2.5110],
            ['mireille.proprietaire@vimmo.bj', 'Résidence Émeraude', 'Appartement', 'Boulevard de la Marina', 'Ganhi', 'Cotonou', 118, false, 6.3568, 2.4302],
            ['mireille.proprietaire@vimmo.bj', 'Villa Palmeraie', 'Villa', 'Route de l’aéroport', 'Fidjrossè', 'Cotonou', 245, false, 6.3521, 2.3781],
            ['mireille.proprietaire@vimmo.bj', 'Studio Cocotiers', 'Studio', 'Rue des Cocotiers', 'Cadjèhoun', 'Cotonou', 48, false, 6.3577, 2.3918],
            ['mireille.proprietaire@vimmo.bj', 'Duplex Calavi', 'Duplex', 'Voie pavée Zoca', 'Zoca', 'Abomey-Calavi', 198, false, 6.4482, 2.3523],
            ['mireille.proprietaire@vimmo.bj', 'Boutique Ganhi', 'Boutique', 'Marché Ganhi', 'Ganhi', 'Cotonou', 62, true, 6.3572, 2.4320],
            ['arnaud.proprietaire@vimmo.bj', 'Loft Marina', 'Appartement', 'Avenue Jean-Paul II', 'Les Cocotiers', 'Cotonou', 96, false, 6.3498, 2.4051],
            ['arnaud.proprietaire@vimmo.bj', 'Maison Jardin Porto-Novo', 'Maison', 'Quartier Tokpota', 'Tokpota', 'Porto-Novo', 175, false, 6.4876, 2.6207],
            ['arnaud.proprietaire@vimmo.bj', 'Villa Lac Nokoué', 'Villa', 'Berge du lac', 'Akpakpa', 'Cotonou', 230, false, 6.3808, 2.4577],
            ['arnaud.proprietaire@vimmo.bj', 'Appartement Vedoko', 'Appartement', 'Carrefour Vedoko', 'Vedoko', 'Cotonou', 88, false, 6.3814, 2.3858],
            ['arnaud.proprietaire@vimmo.bj', 'Résidence Calavi Centre', 'Appartement', 'Face mairie', 'Centre', 'Abomey-Calavi', 105, false, 6.4487, 2.3554],
            ['arnaud.proprietaire@vimmo.bj', 'Ferme Familiale Allada', 'Propriété agricole', 'Route d’Allada', 'Sékou', 'Allada', 8500, true, 6.6658, 2.1514],
        ];

        foreach ($rows as $row) {
            $owner = User::where('email', $row[0])->firstOrFail();
            Property::updateOrCreate(
                ['owner_id' => $owner->id, 'name' => $row[1]],
                ['type' => $row[2], 'description' => 'Bien VIMMO géolocalisé, documenté et disponible selon les conditions de l’annonce.', 'address' => $row[3], 'district' => $row[4], 'city' => $row[5], 'surface' => $row[6], 'is_private' => $row[7], 'latitude' => $row[8], 'longitude' => $row[9]],
            );
        }
    }
}
