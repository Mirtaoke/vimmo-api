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
use Illuminate\Validation\ValidationException;

class RentalController extends Controller
{
    public function contracts(Request $r)
    {
        $q = LeaseContract::with(['unit.media', 'unit.property.media', 'owner:id,name,phone', 'tenant:id,name,email,phone', 'schedules']);
        $q->where($r->user()->role === 'owner' ? 'owner_id' : 'tenant_id', $r->user()->id);

        return ApiResponse::success($q->latest()->get());
    }

    public function createTenant(Request $r, Unit $unit)
    {
        abort_unless($unit->property()->where('owner_id', $r->user()->id)->exists(), 403);
        abort_if($unit->property()->where('is_private', true)->exists(), 422, 'Un locataire ne peut être associé qu’à un bien locatif.');
        $r->merge([
            'email' => strtolower(trim((string) $r->input('email'))),
            'phone' => preg_replace('/[\s().-]+/', '', trim((string) $r->input('phone'))),
        ]);
        $normalizedPhone = $this->normalizePhone((string) $r->input('phone'));
        $duplicateErrors = [];
        if (User::whereRaw('LOWER(email) = ?', [(string) $r->input('email')])->exists()) {
            $duplicateErrors['email'] = ['E-mail déjà utilisé.'];
        }
        $phoneAlreadyUsed = User::query()
            ->whereNotNull('phone')
            ->get(['id', 'phone'])
            ->contains(fn (User $user) => $this->normalizePhone((string) $user->phone) === $normalizedPhone);
        if ($phoneAlreadyUsed) {
            $duplicateErrors['phone'] = ['Téléphone déjà utilisé.'];
        }
        if ($duplicateErrors !== []) {
            throw ValidationException::withMessages($duplicateErrors);
        }
        $d = $r->validate([
            'first_name' => 'required|string|max:100',
            'last_name' => 'required|string|max:100',
            'email' => 'required|email|unique:users,email',
            'phone' => 'required|string|max:30|unique:users,phone',
            'starts_at' => 'required|date',
            'ends_at' => 'nullable|date|after:starts_at',
            'deposit_amount' => 'nullable|numeric|min:0',
            'charges_amount' => 'nullable|numeric|min:0',
            'due_day' => 'required|integer|between:1,28',
        ], [
            'email.unique' => 'E-mail déjà utilisé.',
            'phone.unique' => 'Téléphone déjà utilisé.',
            'due_day.between' => 'Le jour d’échéance doit être compris entre 1 et 28.',
        ], [
            'first_name' => 'prénom',
            'last_name' => 'nom',
            'email' => 'adresse e-mail',
            'phone' => 'numéro de téléphone',
            'starts_at' => 'date de début',
            'due_day' => 'jour d’échéance mensuelle',
        ]);

        $rentAmount = (float) $unit->monthly_rent;
        if ($rentAmount <= 0) {
            throw ValidationException::withMessages([
                'unit' => ['Définissez d’abord le loyer du logement.'],
            ]);
        }

        return DB::transaction(function () use ($d, $r, $unit, $rentAmount) {
            $lockedUnit = Unit::query()->lockForUpdate()->findOrFail($unit->id);
            abort_if(
                $lockedUnit->contracts()->where('status', 'active')->exists(),
                422,
                'Ce logement possède déjà un contrat actif.',
            );
            $tenantFields = collect($d)->only(['first_name', 'last_name', 'email', 'phone'])->all();
            $tenant = User::create([...$tenantFields, 'name' => $d['first_name'].' '.$d['last_name'], 'role' => 'tenant', 'password' => Hash::make('password'), 'email_verified_at' => now(), 'phone_verified_at' => now()]);
            $contract = LeaseContract::create([
                'unit_id' => $unit->id,
                'owner_id' => $r->user()->id,
                'tenant_id' => $tenant->id,
                'reference' => 'CTR-'.now()->format('Y').'-'.strtoupper(Str::random(6)),
                'starts_at' => $d['starts_at'],
                'ends_at' => $d['ends_at'] ?? null,
                'rent_amount' => $rentAmount,
                'deposit_amount' => $d['deposit_amount'] ?? 0,
                'charges_amount' => $d['charges_amount'] ?? 0,
                'due_day' => $d['due_day'],
                'status' => 'active',
            ]);
            $contractStart = Carbon::parse($d['starts_at'])->startOfDay();
            $firstDueDate = $contractStart->copy()->day((int) $d['due_day']);
            if ($firstDueDate->lt($contractStart)) {
                $firstDueDate->addMonth();
            }
            $start = $firstDueDate->copy()->startOfMonth();
            $end = isset($d['ends_at']) ? Carbon::parse($d['ends_at'])->startOfMonth() : $start->copy()->addMonths(11);
            while ($start->lte($end)) {
                $dueDate = $start->copy()->day((int) $d['due_day']);
                $status = $dueDate->lt(today()) ? 'late' : ($dueDate->isToday() ? 'due' : 'upcoming');
                RentSchedule::create(['lease_contract_id' => $contract->id, 'period_start' => $start->copy()->startOfMonth(), 'period_end' => $start->copy()->endOfMonth(), 'due_date' => $dueDate, 'amount' => $rentAmount, 'status' => $status]);
                $start->addMonth();
            }
            $lockedUnit->update(['status' => 'occupied']);

            return ApiResponse::success(['tenant' => $tenant, 'contract' => $contract->load('schedules'), 'default_password' => 'password', 'unit_id' => $unit->id], 'Compte locataire créé et lié au logement.', 201);
        });
    }

    private function normalizePhone(string $phone): string
    {
        $digits = preg_replace('/\D+/', '', $phone) ?? '';
        if (str_starts_with($digits, '00229')) {
            $digits = substr($digits, 5);
        } elseif (str_starts_with($digits, '229')) {
            $digits = substr($digits, 3);
        }
        if (strlen($digits) === 10 && str_starts_with($digits, '01')) {
            $digits = substr($digits, 2);
        }

        return $digits;
    }

    public function storeContract(Request $r)
    {
        $d = $r->validate(['unit_id' => 'required|exists:units,id', 'tenant_id' => 'required|exists:users,id', 'starts_at' => 'required|date', 'ends_at' => 'nullable|date|after:starts_at', 'rent_amount' => 'required|numeric|min:1', 'deposit_amount' => 'nullable|numeric|min:0', 'charges_amount' => 'nullable|numeric|min:0', 'due_day' => 'required|integer|between:1,28', 'terms' => 'nullable|string']);
        $unit = Unit::with('property')->findOrFail($d['unit_id']);
        abort_unless($unit->property->owner_id === $r->user()->id, 403);
        abort_if($unit->property->is_private, 422, 'Un contrat locatif ne peut pas être créé pour un bien familial.');

        return DB::transaction(function () use ($d, $r, $unit) {
            $lockedUnit = Unit::query()->lockForUpdate()->findOrFail($unit->id);
            abort_if(
                $lockedUnit->contracts()->where('status', 'active')->exists(),
                422,
                'Ce logement possède déjà un contrat actif.',
            );
            $contract = LeaseContract::create([...$d, 'owner_id' => $r->user()->id, 'reference' => 'CTR-'.now()->format('Y').'-'.strtoupper(Str::random(6)), 'status' => 'active']);
            $contractStart = Carbon::parse($d['starts_at'])->startOfDay();
            $firstDueDate = $contractStart->copy()->day((int) $d['due_day']);
            if ($firstDueDate->lt($contractStart)) {
                $firstDueDate->addMonth();
            }
            $start = $firstDueDate->copy()->startOfMonth();
            $end = isset($d['ends_at']) ? Carbon::parse($d['ends_at'])->startOfMonth() : $start->copy()->addMonths(11);
            while ($start->lte($end)) {
                $dueDate = $start->copy()->day((int) $d['due_day']);
                $status = $dueDate->lt(today()) ? 'late' : ($dueDate->isToday() ? 'due' : 'upcoming');
                RentSchedule::create(['lease_contract_id' => $contract->id, 'period_start' => $start->copy()->startOfMonth(), 'period_end' => $start->copy()->endOfMonth(), 'due_date' => $dueDate, 'amount' => $d['rent_amount'], 'status' => $status]);
                $start->addMonth();
            }$lockedUnit->update(['status' => 'occupied']);

            return ApiResponse::success($contract->load('schedules'), 'Contrat et échéances créés.', 201);
        });
    }

    public function schedules(Request $r)
    {
        $q = RentSchedule::with(['contract.unit.property', 'contract.tenant:id,name'])
            ->whereHas('contract', fn ($x) => $x->where($r->user()->role === 'owner' ? 'owner_id' : 'tenant_id', $r->user()->id))
            ->whereHas('contract', fn ($x) => $x->whereColumn('rent_schedules.due_date', '>=', 'lease_contracts.starts_at'))
            ->where('amount', '>', 0);
        $rows = $q->orderBy('due_date')->get();
        foreach ($rows as $schedule) {
            $amount = (float) $schedule->amount;
            $paid = (float) $schedule->paid_amount;
            $status = $paid >= $amount
                ? 'paid'
                : ($paid > 0
                    ? 'partial'
                    : ($schedule->due_date->lt(today())
                        ? 'late'
                        : ($schedule->due_date->isToday() ? 'due' : 'upcoming')));
            if ($schedule->status !== $status) {
                $schedule->update(['status' => $status]);
            }
        }

        return ApiResponse::success($rows);
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
        $rows = DB::table('receipts')
            ->join('payments', 'payments.id', '=', 'receipts.payment_id')
            ->join('lease_contracts', 'lease_contracts.id', '=', 'payments.lease_contract_id')
            ->join('units', 'units.id', '=', 'lease_contracts.unit_id')
            ->join('properties', 'properties.id', '=', 'units.property_id')
            ->join('users as tenants', 'tenants.id', '=', 'lease_contracts.tenant_id')
            ->where($r->user()->role === 'owner' ? 'lease_contracts.owner_id' : 'lease_contracts.tenant_id', $r->user()->id)
            ->select('receipts.*', 'payments.amount', 'payments.paid_at', 'lease_contracts.reference as contract_reference', 'units.reference as unit_reference', 'properties.name as property_name', 'tenants.name as tenant_name')
            ->latest('receipts.generated_at')->get()->map(function ($receipt) {
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
