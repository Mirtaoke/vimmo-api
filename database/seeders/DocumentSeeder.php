<?php

namespace Database\Seeders;

use App\Models\LeaseContract;
use App\Models\Media;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Storage;

class DocumentSeeder extends Seeder
{
    public function run(): void
    {
        $c = LeaseContract::firstOrFail();
        foreach ([['Contrat de location signé', 'contract', 'contrat_vimmo_demo.pdf'], ['État des lieux d’entrée', 'inspection', 'etat_des_lieux_demo.pdf']] as $d) {
            $path = 'contracts/'.$c->id.'/'.$d[2];
            $pdf = Pdf::loadHTML('<h1>VIMMO</h1><h2>'.e($d[0]).'</h2><p>Document de démonstration sécurisé.</p>');
            Storage::disk('private')->put($path, $pdf->output());
            Media::updateOrCreate(['mediable_type' => LeaseContract::class, 'mediable_id' => $c->id, 'collection' => 'documents', 'label' => $d[0]], ['user_id' => $c->owner_id, 'disk' => 'private', 'path' => $path, 'mime_type' => 'application/pdf', 'size' => Storage::disk('private')->size($path), 'metadata' => ['type' => $d[1], 'original_name' => $d[2]]]);
        }
    }
}
