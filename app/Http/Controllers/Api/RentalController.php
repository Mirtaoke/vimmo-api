<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Inspection;
use App\Models\LeaseContract;
use App\Models\MaintenanceRequest;
use App\Models\Payment;
use App\Models\Receipt;
use App\Models\RentSchedule;
use App\Models\Unit;
use App\Models\User;
use App\Services\PaymentService;
use App\Support\ApiResponse;
use Barryvdh\DomPDF\Facade\Pdf;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class RentalController extends Controller
{
    public function contracts(Request $r)
    {
        $q = LeaseContract::with(['unit.property', 'owner:id,name,phone', 'tenant:id,name,email,phone', 'schedules']);
        $q->where($r->user()->role === 'owner' ? 'owner_id' : 'tenant_id', $r->user()->id);

        return ApiResponse::success($q->latest()->get());
    }

    public function createTenant(Request $r, Unit $unit)
    {
        abort_unless($unit->property()->where('owner_id', $r->user()->id)->exists(), 403);
        $d = $r->validate(['first_name' => 'required|string', 'last_name' => 'required|string', 'email' => 'required|email|unique:users,email', 'phone' => 'required|string|unique:users,phone']);
        $tenant = User::create([...$d, 'name' => $d['first_name'].' '.$d['last_name'], 'role' => 'tenant', 'password' => Hash::make('password')]);

        return ApiResponse::success(['tenant' => $tenant, 'default_password' => 'password', 'unit_id' => $unit->id], 'Compte locataire créé.', 201);
    }

    public function storeContract(Request $r)
    {
        $d = $r->validate(['unit_id' => 'required|exists:units,id', 'tenant_id' => 'required|exists:users,id', 'starts_at' => 'required|date', 'ends_at' => 'nullable|date|after:starts_at', 'rent_amount' => 'required|numeric|min:1', 'deposit_amount' => 'nullable|numeric|min:0', 'charges_amount' => 'nullable|numeric|min:0', 'due_day' => 'required|integer|between:1,28', 'terms' => 'nullable|string']);
        $unit = Unit::with('property')->findOrFail($d['unit_id']);
        abort_unless($unit->property->owner_id === $r->user()->id, 403);

        return DB::transaction(function () use ($d, $r, $unit) {
            $contract = LeaseContract::create([...$d, 'owner_id' => $r->user()->id, 'reference' => 'CTR-'.now()->format('Y').'-'.strtoupper(Str::random(6)), 'status' => 'active']);
            $start = Carbon::parse($d['starts_at'])->startOfMonth();
            $end = isset($d['ends_at']) ? Carbon::parse($d['ends_at']) : $start->copy()->addMonths(11);
            while ($start->lte($end)) {
                RentSchedule::create(['lease_contract_id' => $contract->id, 'period_start' => $start->copy()->startOfMonth(), 'period_end' => $start->copy()->endOfMonth(), 'due_date' => $start->copy()->day((int) $d['due_day']), 'amount' => $d['rent_amount'], 'status' => $start->isFuture() ? 'upcoming' : 'due']);
                $start->addMonth();
            }$unit->update(['status' => 'occupied']);

            return ApiResponse::success($contract->load('schedules'), 'Contrat et échéances créés.', 201);
        });
    }

    public function schedules(Request $r)
    {
        $q = RentSchedule::with('contract.unit.property')->whereHas('contract', fn ($x) => $x->where($r->user()->role === 'owner' ? 'owner_id' : 'tenant_id', $r->user()->id));

        return ApiResponse::success($q->orderBy('due_date')->get());
    }

    public function payments(Request $r)
    {
        $q = Payment::with(['contract.unit.property', 'schedules', 'receipt'])->whereHas('contract', fn ($x) => $x->where($r->user()->role === 'owner' ? 'owner_id' : 'tenant_id', $r->user()->id));

        return ApiResponse::success($q->latest()->get());
    }

    public function pay(Request $r)
    {
        $d = $r->validate(['lease_contract_id' => 'required|exists:lease_contracts,id', 'schedule_ids' => 'required|array|min:1', 'schedule_ids.*' => 'exists:rent_schedules,id', 'amount' => 'nullable|numeric|min:1', 'method' => 'required|in:cash,mtn_momo,moov_money,bank_transfer,cheque,other', 'proof' => 'required|file|mimes:jpg,jpeg,png,pdf|max:10240', 'note' => 'nullable|string']);
        $contract = LeaseContract::findOrFail($d['lease_contract_id']);
        abort_unless($contract->tenant_id === $r->user()->id, 403);
        $schedules = RentSchedule::where('lease_contract_id', $contract->id)->whereIn('id', $d['schedule_ids'])->orderBy('due_date')->get();
        abort_unless($schedules->count() === count(array_unique($d['schedule_ids'])), 422, 'Certaines échéances ne correspondent pas au contrat.');
        $alreadyPending = Payment::where('lease_contract_id', $contract->id)
            ->where('payer_id', $r->user()->id)
            ->where('status', 'pending')
            ->whereHas('schedules', fn ($query) => $query->whereIn('rent_schedules.id', $d['schedule_ids']))
            ->exists();
        abort_if($alreadyPending, 422, 'Un paiement est déjà en attente de confirmation pour cette échéance.');
        $remaining = $schedules->sum(fn ($s) => max(0, (float) $s->amount - (float) $s->paid_amount));
        $amount = isset($d['amount']) ? (float) $d['amount'] : $remaining;
        abort_if($amount > $remaining, 422, 'Le montant dépasse le solde des échéances sélectionnées.');
        $path = $r->file('proof')->store('payment-proofs', 'private');

        $payment = $this->createPayment($contract, $schedules, $amount, $d['method'], $r->user()->id, $path, $d['note'] ?? null);
        DB::table('notifications')->insert(['user_id' => $contract->owner_id, 'type' => 'payment', 'title' => 'Paiement à vérifier', 'body' => 'Le locataire a déclaré un paiement de '.number_format($amount, 0, ',', ' ').' FCFA.', 'data' => json_encode(['payment_id' => $payment->id]), 'created_at' => now(), 'updated_at' => now()]);

        return ApiResponse::success($payment, 'Paiement envoyé pour confirmation.', 201);
    }

    public function recordPayment(Request $r, PaymentService $service)
    {
        $d = $r->validate(['lease_contract_id' => 'required|exists:lease_contracts,id', 'schedule_ids' => 'required|array|min:1', 'schedule_ids.*' => 'exists:rent_schedules,id', 'amount' => 'required|numeric|min:1', 'method' => 'required|in:cash,mtn_momo,moov_money,bank_transfer,cheque,other', 'proof' => 'nullable|file|mimes:jpg,jpeg,png,pdf|max:10240', 'note' => 'nullable|string']);
        $contract = LeaseContract::findOrFail($d['lease_contract_id']);
        abort_unless($contract->owner_id === $r->user()->id, 403);
        $schedules = RentSchedule::where('lease_contract_id', $contract->id)->whereIn('id', $d['schedule_ids'])->orderBy('due_date')->get();
        abort_unless($schedules->count() === count(array_unique($d['schedule_ids'])), 422, 'Certaines échéances ne correspondent pas au contrat.');
        $remaining = $schedules->sum(fn ($s) => max(0, (float) $s->amount - (float) $s->paid_amount));
        abort_if((float) $d['amount'] > $remaining, 422, 'Le montant dépasse le solde des échéances sélectionnées.');
        $path = $r->hasFile('proof') ? $r->file('proof')->store('payment-proofs', 'private') : null;
        $payment = $this->createPayment($contract, $schedules, (float) $d['amount'], $d['method'], $contract->tenant_id, $path, $d['note'] ?? 'Paiement enregistré par le propriétaire');

        return ApiResponse::success($service->confirm($payment, $r->user()->id), 'Paiement enregistré, ventilé et quittance générée.', 201);
    }

    public function downloadProof(Request $r, Payment $payment)
    {
        $contract = $payment->contract;
        abort_unless(in_array($r->user()->id, [$contract->owner_id, $contract->tenant_id], true), 403);
        abort_unless($payment->proof_path && Storage::disk('private')->exists($payment->proof_path), 404, 'Aucun justificatif disponible.');

        return Storage::disk('private')->download($payment->proof_path);
    }

    public function confirm(Request $r, Payment $payment, PaymentService $service)
    {
        abort_unless($payment->contract()->where('owner_id', $r->user()->id)->exists(), 403);

        return ApiResponse::success($service->confirm($payment, $r->user()->id), 'Paiement confirmé et quittance générée.');
    }

    public function reject(Request $r, Payment $payment)
    {
        abort_unless($payment->contract()->where('owner_id', $r->user()->id)->exists(), 403);
        abort_unless($payment->status === 'pending', 422, 'Seul un paiement en attente peut être rejeté.');
        $d = $r->validate(['reason' => 'required|string|max:500']);
        $payment->update(['status' => 'rejected', 'confirmed_by' => $r->user()->id, 'confirmed_at' => now(), 'note' => trim(($payment->note ? $payment->note."\n" : '').'Motif du rejet : '.$d['reason'])]);
        DB::table('notifications')->insert(['user_id' => $payment->payer_id, 'type' => 'payment', 'title' => 'Paiement non validé', 'body' => 'Le paiement '.$payment->reference.' a été rejeté : '.$d['reason'], 'data' => json_encode(['payment_id' => $payment->id]), 'created_at' => now(), 'updated_at' => now()]);

        return ApiResponse::success($payment->fresh(['contract.unit.property', 'schedules']), 'Paiement rejeté.');
    }

    public function receipts(Request $r)
    {
        $rows = DB::table('receipts')->join('payments', 'payments.id', '=', 'receipts.payment_id')->join('lease_contracts', 'lease_contracts.id', '=', 'payments.lease_contract_id')->where($r->user()->role === 'owner' ? 'lease_contracts.owner_id' : 'lease_contracts.tenant_id', $r->user()->id)->select('receipts.*', 'payments.amount', 'payments.paid_at')->latest('receipts.generated_at')->get()->map(function ($receipt) {
            $receipt->download_path = '/receipts/'.$receipt->id.'/download';

            return $receipt;
        });

        return ApiResponse::success($rows);
    }

    public function downloadReceipt(Request $r, Receipt $receipt)
    {
        $receipt->load(['payment.contract.owner', 'payment.contract.tenant', 'payment.contract.unit.property', 'payment.schedules']);
        $contract = $receipt->payment->contract;
        abort_unless(in_array($r->user()->id, [$contract->owner_id, $contract->tenant_id], true), 403);
        $periods = $receipt->payment->schedules->map(fn ($s) => Carbon::parse($s->period_start)->locale('fr')->translatedFormat('F Y'))->join(', ');
        $html = view('pdf.receipt', ['receipt' => $receipt, 'payment' => $receipt->payment, 'contract' => $contract, 'periods' => $periods])->render();

        return Pdf::loadHTML($html)->setPaper('a4')->download('quittance-'.$receipt->reference.'.pdf');
    }

    public function verifyReceipt(string $token)
    {
        $receipt = Receipt::with(['payment.contract.unit.property', 'payment.contract.owner:id,name', 'payment.contract.tenant:id,name', 'payment.schedules'])->where('verification_token', $token)->firstOrFail();

        return ApiResponse::success($receipt, 'Quittance authentique.');
    }

    public function unitTimeline(Request $r, Unit $unit)
    {
        $unit->load('property');
        $contractQuery = LeaseContract::where('unit_id', $unit->id);
        abort_unless($unit->property->owner_id === $r->user()->id || (clone $contractQuery)->where('tenant_id', $r->user()->id)->exists(), 403);
        $contracts = (clone $contractQuery)->with(['tenant:id,name', 'schedules', 'payments.receipt'])->latest('starts_at')->get();
        $contractIds = $contracts->pluck('id');
        $inspections = Inspection::whereIn('lease_contract_id', $contractIds)->latest('inspection_date')->get();
        $maintenance = MaintenanceRequest::where('unit_id', $unit->id)->latest()->get();

        return ApiResponse::success(['unit' => $unit, 'contracts' => $contracts, 'inspections' => $inspections, 'maintenance' => $maintenance]);
    }

    private function createPayment(LeaseContract $contract, $schedules, float $amount, string $method, int $payerId, ?string $proof, ?string $note): Payment
    {
        return DB::transaction(function () use ($contract, $schedules, $amount, $method, $payerId, $proof, $note) {
            $payment = Payment::create(['lease_contract_id' => $contract->id, 'payer_id' => $payerId, 'reference' => 'PAY-'.now()->format('Ymd').'-'.strtoupper(Str::random(6)), 'amount' => $amount, 'method' => $method, 'status' => 'pending', 'proof_path' => $proof, 'paid_at' => now(), 'note' => $note]);
            $left = $amount;
            foreach ($schedules as $schedule) {
                $balance = max(0, (float) $schedule->amount - (float) $schedule->paid_amount);
                $allocated = min($left, $balance);
                if ($allocated > 0) {
                    $payment->schedules()->attach($schedule->id, ['amount' => $allocated]);
                }$left -= $allocated;
                if ($left <= 0) {
                    break;
                }
            }

            return $payment->load('schedules');
        });
    }
}
