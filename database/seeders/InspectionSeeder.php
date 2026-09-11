<?php

namespace Database\Seeders;

use App\Models\Inspection;
use App\Models\InspectionItem;
use App\Models\LeaseContract;
use Illuminate\Database\Seeder;

class InspectionSeeder extends Seeder
{
    public function run(): void
    {
        $c = LeaseContract::firstOrFail();
        $i = Inspection::updateOrCreate(['reference' => 'EDL-2026-000125'], ['lease_contract_id' => $c->id, 'created_by' => $c->owner_id, 'type' => 'entry', 'inspection_date' => $c->starts_at, 'status' => 'completed', 'readings' => ['electricity' => '001284', 'water' => '00492'], 'keys' => ['entrée' => 2, 'boîte_aux_lettres' => 1]]);
        foreach ([['Salon', 'Murs', 'very_good'], ['Cuisine', 'Robinetterie', 'good'], ['Chambre principale', 'Climatisation', 'very_good']] as $v) {
            InspectionItem::updateOrCreate(['inspection_id' => $i->id, 'room' => $v[0], 'element' => $v[1]], ['condition' => $v[2], 'comment' => 'Contrôle effectué sur place.']);
        }
    }
}
