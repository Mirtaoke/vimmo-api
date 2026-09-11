<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\RentSchedule;
use App\Support\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ArrearController extends Controller
{
    public function index(Request $r)
    {
        abort_unless($r->user()->role === 'owner', 403);
        RentSchedule::whereDate('due_date', '<', today())->whereColumn('paid_amount', '<', 'amount')->whereIn('status', ['upcoming', 'due', 'partial'])->update(['status' => 'late']);
        $rows = RentSchedule::with(['contract.tenant:id,name,email,phone', 'contract.unit.property'])->whereHas('contract', fn ($q) => $q->where('owner_id', $r->user()->id))->whereIn('status', ['late', 'unpaid', 'partial'])->orderBy('due_date')->get()->map(function ($row) {
            $row->setAttribute('remaining_amount', (float) $row->amount - (float) $row->paid_amount);
            $row->setAttribute('days_late', max(0, $row->due_date->diffInDays(today())));

            return $row;
        });

        return ApiResponse::success($rows);
    }

    public function remind(Request $r, RentSchedule $schedule)
    {
        abort_unless($schedule->contract->owner_id === $r->user()->id, 403);
        abort_unless((float) $schedule->paid_amount < (float) $schedule->amount, 422, 'Cette échéance est déjà réglée.');
        DB::table('notifications')->insert(['user_id' => $schedule->contract->tenant_id, 'type' => 'rent_reminder', 'title' => 'Rappel de loyer', 'body' => 'L’échéance du '.$schedule->due_date->format('d/m/Y').' présente un solde de '.number_format((float) $schedule->amount - (float) $schedule->paid_amount, 0, ',', ' ').' FCFA.', 'data' => json_encode(['schedule_id' => $schedule->id, 'contract_id' => $schedule->lease_contract_id]), 'created_at' => now(), 'updated_at' => now()]);

        return ApiResponse::success(null,'Rappel envoyé au locataire.');
    }
}
