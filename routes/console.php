<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Schedule::call(function () {
    $today = today()->toDateString();
    $lateSchedules = DB::table('rent_schedules')
        ->join('lease_contracts', 'lease_contracts.id', '=', 'rent_schedules.lease_contract_id')
        ->where('lease_contracts.status', 'active')
        ->whereDate('rent_schedules.due_date', '<', $today)
        ->whereColumn('rent_schedules.due_date', '>=', 'lease_contracts.starts_at')
        ->whereColumn('rent_schedules.paid_amount', '<', 'rent_schedules.amount')
        ->select(
            'rent_schedules.id',
            'rent_schedules.amount',
            'rent_schedules.paid_amount',
            'lease_contracts.tenant_id',
        )
        ->get();

    foreach ($lateSchedules as $schedule) {
        DB::table('rent_schedules')->where('id', $schedule->id)->update([
            'status' => (float) $schedule->paid_amount > 0 ? 'partial' : 'late',
            'updated_at' => now(),
        ]);
        $alreadySent = DB::table('notifications')
            ->where('user_id', $schedule->tenant_id)
            ->where('type', 'rent_late')
            ->whereDate('created_at', $today)
            ->where('data', 'like', '%"schedule_id":'.$schedule->id.'%')
            ->exists();
        if (! $alreadySent) {
            $balance = max(0, (float) $schedule->amount - (float) $schedule->paid_amount);
            DB::table('notifications')->insert([
                'user_id' => $schedule->tenant_id,
                'type' => 'rent_late',
                'title' => 'Loyer en retard',
                'body' => 'Votre solde de '.number_format($balance, 0, ',', ' ').' FCFA reste à régulariser.',
                'data' => json_encode(['schedule_id' => $schedule->id]),
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }
})->dailyAt('08:00')->name('vimmo-rent-reminders')->withoutOverlapping();
