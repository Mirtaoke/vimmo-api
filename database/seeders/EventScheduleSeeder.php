<?php

namespace Database\Seeders;

use App\Models\Event;
use Illuminate\Database\Seeder;

class EventScheduleSeeder extends Seeder
{
    public function run(): void
    {
        foreach (Event::all() as $event) {
            for ($day = $event->starts_at->copy()->startOfDay(); $day->lte($event->ends_at->copy()->startOfDay()); $day->addDay()) {
                $event->schedules()->updateOrCreate(['date' => $day->toDateString()], ['start_time' => $day->isSameDay($event->starts_at) ? $event->starts_at->format('H:i') : '10:00', 'end_time' => $day->isSameDay($event->ends_at) ? $event->ends_at->format('H:i') : '23:00']);
            }
        }
    }
}
