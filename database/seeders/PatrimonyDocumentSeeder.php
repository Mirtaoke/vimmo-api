<?php

namespace Database\Seeders;

use App\Models\Media;
use App\Models\Property;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Storage;

class PatrimonyDocumentSeeder extends Seeder
{
    public function run(): void
    {
        foreach (Property::where('is_private', true)->get() as $property) {
            foreach ([['Titre de propriété', 'titre_propriete.pdf'], ['Plan cadastral', 'plan_cadastral.pdf']] as [$label,$name]) {
                $path = 'vault/'.$property->id.'/'.$name;
                $pdf = Pdf::loadHTML('<h1>VIMMO</h1><h2>'.e($label).'</h2><p>Bien : '.e($property->name).'</p><p>Document patrimonial de démonstration.</p>');
                Storage::disk('private')->put($path, $pdf->output());
                Media::updateOrCreate(['mediable_type' => Property::class, 'mediable_id' => $property->id, 'collection' => 'documents', 'label' => $label], ['user_id' => $property->owner_id, 'disk' => 'private', 'path' => $path, 'mime_type' => 'application/pdf', 'size' => Storage::disk('private')->size($path), 'metadata' => ['type' => 'patrimony', 'original_name' => $name]]);
            }
        }
    }
}
