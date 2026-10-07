<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\ApiResponse;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    public function __invoke(Request $request)
    {
        $u = $request->user();
        if ($u->role === 'owner') {
            $monthStart = now()->startOfMonth();
            $monthEnd = now()->endOfMonth();
            $ownedUnits = DB::table('units')->join('properties', 'properties.id', '=', 'units.property_id')->where('properties.owner_id', $u->id);
            $contracts = DB::table('lease_contracts')->where('owner_id', $u->id);
            $ownerPayments = DB::table('payments')->join('lease_contracts', 'lease_contracts.id', '=', 'payments.lease_contract_id')->where('lease_contracts.owner_id', $u->id);
            $ownerSchedules = DB::table('rent_schedules')->join('lease_contracts', 'lease_contracts.id', '=', 'rent_schedules.lease_contract_id')->where('lease_contracts.owner_id', $u->id);
            $monthSchedules = (clone $ownerSchedules)->whereBetween('rent_schedules.period_start', [$monthStart->toDateString(), $monthEnd->toDateString()]);
            $rentDueMonth = (float) (clone $monthSchedules)->sum('rent_schedules.amount');
            $rentCollectedForMonth = (float) (clone $monthSchedules)->sum('rent_schedules.paid_amount');
            $data = [
                'properties' => DB::table('properties')->where('owner_id', $u->id)->count(),
                'rental_properties' => DB::table('properties')->where('owner_id', $u->id)->where('is_private', false)->count(),
                'private_properties' => DB::table('properties')->where('owner_id', $u->id)->where('is_private', true)->count(),
                'units' => (clone $ownedUnits)->count(),
                'occupied_units' => (clone $ownedUnits)->where('units.status', 'occupied')->count(),
                'tenants' => (clone $contracts)->where('status', 'active')->distinct('tenant_id')->count('tenant_id'),
                'active_contracts' => (clone $contracts)->where('status', 'active')->count(),
                'active_listings' => DB::table('listings')->where('owner_id', $u->id)->where('status', 'published')->count(),
                'pending_visits' => DB::table('visit_requests')
                    ->join('listings', 'listings.id', '=', 'visit_requests.listing_id')
                    ->where('listings.owner_id', $u->id)
                    ->whereIn('visit_requests.status', ['requested', 'accepted', 'confirmed'])
                    ->count(),
                'pending_applications' => DB::table('rental_applications')
                    ->join('listings', 'listings.id', '=', 'rental_applications.listing_id')
                    ->where('listings.owner_id', $u->id)
                    ->whereIn('rental_applications.status', ['submitted', 'reviewing'])
                    ->count(),
                'pending_payments' => (clone $ownerPayments)->where('payments.status', 'pending')->count(),
                'open_maintenance' => DB::table('maintenance_requests')->join('units', 'units.id', '=', 'maintenance_requests.unit_id')->join('properties', 'properties.id', '=', 'units.property_id')->where('properties.owner_id', $u->id)->whereNotIn('maintenance_requests.status', ['resolved', 'closed'])->count(),
                'pending_inspections' => DB::table('inspections')->join('lease_contracts', 'lease_contracts.id', '=', 'inspections.lease_contract_id')->where('lease_contracts.owner_id', $u->id)->where('inspections.status', '!=', 'completed')->count(),
                'rent_received' => (float) (clone $ownerPayments)->where('payments.status', 'confirmed')->sum('payments.amount'),
                'rent_received_month' => (float) (clone $ownerPayments)->where('payments.status', 'confirmed')->whereBetween('payments.confirmed_at', [$monthStart, $monthEnd])->sum('payments.amount'),
                'rent_due_month' => $rentDueMonth,
                'rent_collected_for_month' => $rentCollectedForMonth,
                'collection_rate' => $rentDueMonth > 0 ? round(min(100, ($rentCollectedForMonth / $rentDueMonth) * 100), 1) : 0,
                'rent_pending' => (float) (clone $ownerSchedules)
                    ->whereDate('rent_schedules.due_date', '<', today())
                    ->whereColumn('rent_schedules.due_date', '>=', 'lease_contracts.starts_at')
                    ->whereNotIn('rent_schedules.status', ['paid', 'cancelled'])
                    ->sum(DB::raw('CASE WHEN rent_schedules.amount > rent_schedules.paid_amount THEN rent_schedules.amount - rent_schedules.paid_amount ELSE 0 END')),
            ];
        } elseif ($u->role === 'tenant') {
            $contract = DB::table('lease_contracts')
                ->join('units', 'units.id', '=', 'lease_contracts.unit_id')
                ->join('properties', 'properties.id', '=', 'units.property_id')
                ->where('lease_contracts.tenant_id', $u->id)
                ->where('lease_contracts.status', 'active')
                ->select(
                    'lease_contracts.*',
                    'units.reference as unit_reference',
                    'properties.name as property_name',
                )
                ->first();
            $contractId = $contract?->id;
            $unitId = $contract?->unit_id;
            $nextRent = $contractId ? DB::table('rent_schedules')
                ->where('lease_contract_id', $contractId)
                ->whereDate('due_date', '>=', $contract->starts_at)
                ->where('amount', '>', 0)
                ->whereColumn('paid_amount', '<', 'amount')
                ->orderBy('due_date')
                ->first() : null;
            if ($nextRent) {
                $dueDate = Carbon::parse($nextRent->due_date)->startOfDay();
                $nextRent->balance = max(0, (float) $nextRent->amount - (float) $nextRent->paid_amount);
                $nextRent->status = (float) $nextRent->paid_amount > 0
                    ? 'partial'
                    : (today()->gt($dueDate) ? 'late' : (today()->isSameDay($dueDate) ? 'due' : 'upcoming'));
            }
            $lastPayment = DB::table('payments')
                ->join('lease_contracts', 'lease_contracts.id', '=', 'payments.lease_contract_id')
                ->where('lease_contracts.tenant_id', $u->id)
                ->where('payments.status', 'confirmed')
                ->select('payments.id', 'payments.reference', 'payments.amount', 'payments.method', 'payments.paid_at')
                ->latest('payments.paid_at')
                ->first();
            $data = [
                'contract' => $contract,
                'next_rent' => $nextRent,
                'last_payment' => $lastPayment,
                'rent_paid' => (float) DB::table('payments')->join('lease_contracts', 'lease_contracts.id', '=', 'payments.lease_contract_id')->where('lease_contracts.tenant_id', $u->id)->where('payments.status', 'confirmed')->sum('payments.amount'),
                'pending_payments' => $contractId ? DB::table('payments')->where('lease_contract_id', $contractId)->where('status', 'pending')->count() : 0,
                'receipts' => $contractId ? DB::table('receipts')->join('payments', 'payments.id', '=', 'receipts.payment_id')->where('payments.lease_contract_id', $contractId)->count() : 0,
                'documents' => $contractId ? DB::table('media')->where('mediable_type', 'App\\Models\\LeaseContract')->where('mediable_id', $contractId)->count() + DB::table('receipts')->join('payments', 'payments.id', '=', 'receipts.payment_id')->where('payments.lease_contract_id', $contractId)->count() : 0,
                'payments' => $contractId ? DB::table('payments')->where('lease_contract_id', $contractId)->where('status', 'confirmed')->count() : 0,
                'pending_inspections' => $contractId ? DB::table('inspections')->where('lease_contract_id', $contractId)->where('status', '!=', 'completed')->count() : 0,
                'open_maintenance' => $unitId ? DB::table('maintenance_requests')->where('unit_id', $unitId)->whereNotIn('status', ['resolved', 'closed'])->count() : 0,
            ];
        } else {
            $data = [
                'favorites' => DB::table('favorites')->where('user_id', $u->id)->count(),
                'saved_searches' => DB::table('saved_searches')->where('user_id', $u->id)->count(),
                'visits' => DB::table('visit_requests')->where('requester_id', $u->id)->count(),
                'applications' => DB::table('rental_applications')->where('applicant_id', $u->id)->count(),
            ];
        }

        $data['unread_messages'] = DB::table('messages')
            ->join('conversation_participants', 'conversation_participants.conversation_id', '=', 'messages.conversation_id')
            ->where('conversation_participants.user_id', $u->id)
            ->where('messages.sender_id', '!=', $u->id)
            ->where(function ($query) {
                $query->whereNull('conversation_participants.last_read_at')
                    ->orWhereColumn('messages.created_at', '>', 'conversation_participants.last_read_at');
            })
            ->distinct()
            ->count('messages.id');
        $data['unread_notifications'] = DB::table('notifications')
            ->where('user_id', $u->id)
            ->whereNull('read_at')
            ->count();

        return ApiResponse::success($data);
    }
}
