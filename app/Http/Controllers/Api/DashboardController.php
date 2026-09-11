<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    public function __invoke(Request $request)
    {
        $u = $request->user();
        if ($u->role === 'owner') {
            $ownedUnits = DB::table('units')->join('properties', 'properties.id', '=', 'units.property_id')->where('properties.owner_id', $u->id);
            $contracts = DB::table('lease_contracts')->where('owner_id', $u->id);
            $data = [
                'properties' => DB::table('properties')->where('owner_id', $u->id)->where('is_private', false)->count(),
                'private_properties' => DB::table('properties')->where('owner_id', $u->id)->where('is_private', true)->count(),
                'units' => (clone $ownedUnits)->count(),
                'occupied_units' => (clone $ownedUnits)->where('units.status', 'occupied')->count(),
                'tenants' => (clone $contracts)->where('status', 'active')->distinct('tenant_id')->count('tenant_id'),
                'active_listings' => DB::table('listings')->where('owner_id', $u->id)->where('status', 'published')->count(),
                'pending_payments' => DB::table('payments')->join('lease_contracts', 'lease_contracts.id', '=', 'payments.lease_contract_id')->where('lease_contracts.owner_id', $u->id)->where('payments.status', 'pending')->count(),
                'open_maintenance' => DB::table('maintenance_requests')->join('units', 'units.id', '=', 'maintenance_requests.unit_id')->join('properties', 'properties.id', '=', 'units.property_id')->where('properties.owner_id', $u->id)->whereNotIn('maintenance_requests.status', ['resolved', 'closed'])->count(),
                'pending_inspections' => DB::table('inspections')->join('lease_contracts', 'lease_contracts.id', '=', 'inspections.lease_contract_id')->where('lease_contracts.owner_id', $u->id)->where('inspections.status', '!=', 'completed')->count(),
                'rent_received' => (float) DB::table('payments')->join('lease_contracts', 'lease_contracts.id', '=', 'payments.lease_contract_id')->where('lease_contracts.owner_id', $u->id)->where('payments.status', 'confirmed')->sum('payments.amount'),
                'rent_pending' => (float) DB::table('rent_schedules')->join('lease_contracts', 'lease_contracts.id', '=', 'rent_schedules.lease_contract_id')->where('lease_contracts.owner_id', $u->id)->whereIn('rent_schedules.status', ['due', 'late', 'unpaid'])->sum(DB::raw('amount-paid_amount')),
            ];
        } elseif ($u->role === 'tenant') {
            $contract = DB::table('lease_contracts')->where('tenant_id', $u->id)->where('status', 'active')->first();
            $contractId = $contract?->id;
            $unitId = $contract?->unit_id;
            $data = [
                'contract' => $contract,
                'rent_paid' => (float) DB::table('payments')->join('lease_contracts', 'lease_contracts.id', '=', 'payments.lease_contract_id')->where('lease_contracts.tenant_id', $u->id)->where('payments.status', 'confirmed')->sum('payments.amount'),
                'unread_messages' => DB::table('conversation_participants')->where('user_id', $u->id)->whereNull('last_read_at')->count(),
                'pending_payments' => $contractId ? DB::table('payments')->where('lease_contract_id', $contractId)->where('status', 'pending')->count() : 0,
                'receipts' => $contractId ? DB::table('receipts')->where('lease_contract_id', $contractId)->count() : 0,
                'pending_inspections' => $contractId ? DB::table('inspections')->where('lease_contract_id', $contractId)->where('status', '!=', 'completed')->count() : 0,
                'open_maintenance' => $unitId ? DB::table('maintenance_requests')->where('unit_id', $unitId)->whereNotIn('status', ['resolved', 'closed'])->count() : 0,
            ];
        } else {
            $data = ['favorites' => DB::table('favorites')->where('user_id', $u->id)->count(), 'saved_searches' => DB::table('saved_searches')->where('user_id', $u->id)->count(), 'visits' => DB::table('visit_requests')->where('requester_id', $u->id)->count()];
        }

        return ApiResponse::success($data);
    }
}
