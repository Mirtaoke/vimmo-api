<?php

namespace Database\Seeders;

use App\Models\Event;
use App\Models\EventCategory;
use App\Models\User;
use Illuminate\Database\Seeder;

class EventSeeder extends Seeder
{
    public function run(): void
    {
        $organizers = User::where('role', 'organizer')->get()->values();
        $rows = [['Cotonou Rooftop Session', 'Concert', 'Afro-fusion & Live', 'Chic décontracté', 'Une soirée musicale premium au-dessus de la ville.', 'Live, gastronomie et panorama sur Cotonou.', 'Rooftop Ganhi', 12, 6.3568, 2.4302], ['Festival Lumières de Ouidah', 'Culture', 'Patrimoine & lumière', 'Élégance africaine', 'Un parcours artistique, musical et lumineux au cœur de Ouidah.', 'Expositions, performances, restauration et espace famille.', 'Place Chacha', 24, 6.3644, 2.0851], ['VIMMO Business Forum', 'Conférence', 'Investissement immobilier', 'Business chic', 'Rencontres et conférences consacrées au patrimoine et à l’immobilier.', 'Panels, réseautage et ateliers pratiques.', 'Palais des Congrès', 35, 6.3579, 2.4036], ['Family Garden Day', 'Famille', 'Nature & jeux', 'Décontracté coloré', 'Une journée en plein air pensée pour les familles.', 'Jeux, ateliers, déjeuner et animations jeunesse.', 'Jardin botanique', 48, 6.4098, 2.3401]];
        foreach ($rows as $index => $row) {
            $start = now()->addDays($row[7])->setTime($index === 3 ? 10 : 19, 0);
            Event::updateOrCreate(['title' => $row[0]], ['organizer_id' => $organizers[$index % $organizers->count()]->id, 'event_category_id' => EventCategory::where('name', $row[1])->value('id'), 'theme' => $row[2], 'dress_code' => $row[3], 'description' => $row[4], 'experience' => $row[5], 'place' => $row[6], 'place_description' => 'Localisation vérifiée dans VIMMO', 'starts_at' => $start, 'ends_at' => $start->copy()->addHours($index === 3 ? 8 : 6), 'latitude' => $row[8], 'longitude' => $row[9], 'status' => 'published']);
        }
    }
}
