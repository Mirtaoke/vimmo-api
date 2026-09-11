<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Inspection;
use App\Models\InspectionItem;
use App\Models\LeaseContract;
use App\Models\Media;
use App\Support\ApiResponse;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class InspectionController extends Controller
{
    private function authorized(Request $r, Inspection $i): bool
    {
        $c = $i->contract;

        return in_array($r->user()->id, [$c->owner_id, $c->tenant_id], true);
    }

    private function details(Inspection $i): Inspection
    {
        return $i->load(['contract.unit.property', 'contract.owner:id,name,email,phone', 'contract.tenant:id,name,email,phone', 'items.media', 'validations.user:id,name', 'disputes.user:id,name', 'disputes.item']);
    }

    public function index(Request $r)
    {
        return ApiResponse::success(Inspection::with(['contract.unit.property', 'items.media', 'validations'])->whereHas('contract', fn ($q) => $q->where($r->user()->role === 'owner' ? 'owner_id' : 'tenant_id', $r->user()->id))->latest()->get());
    }

    public function store(Request $r)
    {
        $d = $this->validated($r);
        $contract = LeaseContract::findOrFail($d['lease_contract_id']);
        abort_unless($contract->owner_id === $r->user()->id, 403);

        return DB::transaction(function () use ($d, $r) {
            $items = $d['items'];
            unset($d['items']);
            $inspection = Inspection::create([...$d, 'created_by' => $r->user()->id, 'reference' => 'EDL-'.now()->format('Y').'-'.str_pad((string) (Inspection::max('id') + 1), 6, '0', STR_PAD_LEFT)]);
            $inspection->items()->createMany($items);
            $this->notifyParties($inspection, 'État des lieux créé', 'L’état des lieux '.$inspection->reference.' est disponible.');

            return ApiResponse::success($this->details($inspection), 'État des lieux créé.', 201);
        });
    }

    public function show(Request $r, Inspection $inspection)
    {
        abort_unless($this->authorized($r, $inspection), 403);

        return ApiResponse::success($this->details($inspection));
    }

    public function addMedia(Request $r, Inspection $inspection, InspectionItem $item)
    {
        abort_unless($this->authorized($r, $inspection) && $item->inspection_id === $inspection->id, 403);
        abort_if($inspection->status === 'completed', 422, 'Créez une nouvelle version avant de modifier un état des lieux validé.');
        $d = $r->validate(['files' => 'required|array|min:1|max:10', 'files.*' => 'file|mimes:jpg,jpeg,png,mp4,mov|max:30720', 'legends' => 'nullable|string']);
        $legends = explode('|', $d['legends'] ?? '');
        $created = [];
        foreach ($r->file('files', []) as $index => $file) {
            $created[] = Media::create(['user_id' => $r->user()->id, 'mediable_type' => InspectionItem::class, 'mediable_id' => $item->id, 'collection' => str_starts_with($file->getMimeType(), 'video/') ? 'videos' : 'photos', 'label' => $legends[$index] ?? null, 'disk' => 'private', 'path' => $file->store('inspections/'.$inspection->id, 'private'), 'mime_type' => $file->getMimeType(), 'size' => $file->getSize(), 'metadata' => ['original_name' => $file->getClientOriginalName()]]);
        }

return ApiResponse::success($created, 'Preuves ajoutées.', 201);
    }

    public function validateInspection(Request $r, Inspection $inspection)
    {
        abort_unless($this->authorized($r, $inspection), 403);
        abort_if($inspection->status === 'disputed', 422, 'La contestation doit être traitée avant validation.');
        DB::table('inspection_validations')->updateOrInsert(['inspection_id' => $inspection->id, 'user_id' => $r->user()->id], ['method' => 'electronic', 'ip_address' => $r->ip(), 'validated_at' => now()]);
        $count = DB::table('inspection_validations')->where('inspection_id', $inspection->id)->count();
        $status = $count >= 2 ? 'completed' : ($r->user()->id === $inspection->contract->owner_id ? 'owner_validated' : 'tenant_validated');
        $inspection->update(['status' => $status]);
        if ($status === 'completed') {
            DB::table('inspection_versions')->updateOrInsert(['inspection_id' => $inspection->id, 'version' => $inspection->version], ['created_by' => $r->user()->id, 'snapshot' => json_encode($this->details($inspection)->toArray()), 'reason' => 'Validation par les deux parties', 'created_at' => now(), 'updated_at' => now()]);
            $this->notifyParties($inspection, 'État des lieux validé', 'L’état des lieux '.$inspection->reference.' a été validé par les deux parties.');
        }

return ApiResponse::success($this->details($inspection), 'Validation enregistrée.');
    }

    public function dispute(Request $r, Inspection $inspection)
    {
        abort_unless($this->authorized($r, $inspection), 403);
        $d = $r->validate(['inspection_item_id' => 'nullable|exists:inspection_items,id', 'comment' => 'required|string|max:3000']);
        if (isset($d['inspection_item_id'])) {
            abort_unless($inspection->items()->whereKey($d['inspection_item_id'])->exists(), 422, 'Cet élément n’appartient pas à cet état des lieux.');
        }$id = DB::table('inspection_disputes')->insertGetId([...$d, 'inspection_id' => $inspection->id, 'user_id' => $r->user()->id, 'created_at' => now(), 'updated_at' => now()]);
        $inspection->update(['status' => 'disputed']);
        $this->notifyParties($inspection, 'Contestation enregistrée', $d['comment']);

        return ApiResponse::success(DB::table('inspection_disputes')->find($id), 'Contestation enregistrée.', 201);
    }

    public function respond(Request $r, Inspection $inspection, int $dispute)
    {
        abort_unless($inspection->contract->owner_id === $r->user()->id, 403);
        $d = $r->validate(['response' => 'required|string|max:3000']);
        $updated = DB::table('inspection_disputes')->where(['id' => $dispute, 'inspection_id' => $inspection->id])->update(['response' => $d['response'], 'updated_at' => now()]);
        abort_unless($updated, 404);
        $inspection->update(['status' => 'draft']);

        return ApiResponse::success(DB::table('inspection_disputes')->find($dispute), 'Réponse enregistrée.');
    }

    public function revise(Request $r, Inspection $inspection)
    {
        abort_unless($this->authorized($r, $inspection), 403);
        $d = $r->validate(['reason' => 'required|string|max:1000', 'readings' => 'nullable|array', 'keys' => 'nullable|array', 'equipment' => 'nullable|array', 'items' => 'required|array|min:1', 'items.*.room' => 'required|string', 'items.*.element' => 'required|string', 'items.*.condition' => 'required|in:new,very_good,good,average,bad,out_of_order,not_applicable', 'items.*.comment' => 'nullable|string', 'items.*.anomaly' => 'boolean', 'items.*.exit_comparison' => 'nullable|array']);

        return DB::transaction(function () use ($r, $inspection, $d) {
            DB::table('inspection_versions')->updateOrInsert(['inspection_id' => $inspection->id, 'version' => $inspection->version], ['created_by' => $r->user()->id, 'snapshot' => json_encode($this->details($inspection)->toArray()), 'reason' => $d['reason'], 'created_at' => now(), 'updated_at' => now()]);
            $items = $d['items'];
            unset($d['items'],$d['reason']);
            $inspection->update([...$d, 'version' => $inspection->version + 1, 'status' => 'draft']);
            $inspection->items()->delete();
            $inspection->items()->createMany($items);
            DB::table('inspection_validations')->where('inspection_id', $inspection->id)->delete();

            return ApiResponse::success($this->details($inspection), 'Nouvelle version créée.');
        });
    }

    public function compare(Request $r, Inspection $inspection)
    {
        abort_unless($this->authorized($r, $inspection), 403);
        $entry = Inspection::with('items')->where('lease_contract_id', $inspection->lease_contract_id)->where('type', 'entry')->where('status', 'completed')->latest('inspection_date')->first();
        abort_unless($entry, 404, 'Aucun état des lieux d’entrée validé n’est disponible.');
        $entryItems = $entry->items->keyBy(fn ($item) => mb_strtolower($item->room.'|'.$item->element));
        $comparison = $inspection->items->map(function ($item) use ($entryItems) {
            $before = $entryItems->get(mb_strtolower($item->room.'|'.$item->element));

            return ['room' => $item->room, 'element' => $item->element, 'entry_condition' => $before?->condition, 'current_condition' => $item->condition, 'changed' => $before?->condition !== $item->condition, 'entry_comment' => $before?->comment, 'current_comment' => $item->comment];
        });

        return ApiResponse::success(['entry_reference' => $entry->reference, 'current_reference' => $inspection->reference, 'items' => $comparison]);
    }

    public function downloadPdf(Request $r, Inspection $inspection)
    {
        abort_unless($this->authorized($r, $inspection), 403);
        abort_unless($inspection->status === 'completed', 422, 'Le PDF final est disponible après validation des deux parties.');

        return Pdf::loadView('pdf.inspection', ['inspection' => $this->details($inspection)])->setPaper('a4')->download('etat-des-lieux-'.$inspection->reference.'.pdf');
    }

    private function validated(Request $r): array
    {
        return $r->validate(['lease_contract_id' => 'required|exists:lease_contracts,id', 'type' => 'required|in:entry,exit,intermediate', 'inspection_date' => 'required|date', 'readings' => 'nullable|array', 'keys' => 'nullable|array', 'equipment' => 'nullable|array', 'items' => 'required|array|min:1', 'items.*.room' => 'required|string', 'items.*.element' => 'required|string', 'items.*.condition' => 'required|in:new,very_good,good,average,bad,out_of_order,not_applicable', 'items.*.comment' => 'nullable|string', 'items.*.anomaly' => 'boolean']);
    }

    private function notifyParties(Inspection $inspection, string $title, string $body): void
    {
        foreach ([$inspection->contract->owner_id, $inspection->contract->tenant_id] as $userId) {
            DB::table('notifications')->insert(['user_id' => $userId, 'type' => 'inspection', 'title' => $title, 'body' => $body, 'data' => json_encode(['inspection_id' => $inspection->id]), 'created_at' => now(), 'updated_at' => now()]);
        }
    }
}
