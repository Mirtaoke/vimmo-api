<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\ApiResponse;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class NotificationController extends Controller
{
    public function index(Request $r)
    {
        $notifications = DB::table('notifications')
            ->where('user_id', $r->user()->id)
            ->latest()
            ->paginate(30)
            ->through(function (object $notification): object {
                foreach (['created_at', 'updated_at', 'read_at'] as $field) {
                    if ($notification->{$field} !== null) {
                        $notification->{$field} = Carbon::parse(
                            $notification->{$field},
                            config('app.timezone'),
                        )->utc()->toISOString();
                    }
                }

                return $notification;
            });

        return ApiResponse::success($notifications);
    }

    public function read(Request $r, int $id)
    {
        $updated = DB::table('notifications')->where(['id' => $id, 'user_id' => $r->user()->id])->update(['read_at' => now(), 'updated_at' => now()]);
        abort_unless($updated, 404);

        return ApiResponse::success(null, 'Notification lue.');
    }

    public function readAll(Request $r)
    {
        DB::table('notifications')->where('user_id', $r->user()->id)->whereNull('read_at')->update(['read_at' => now(), 'updated_at' => now()]);

        return ApiResponse::success(null, 'Toutes les notifications sont lues.');
    }

    public function destroy(Request $r, int $id)
    {
        $deleted = DB::table('notifications')
            ->where(['id' => $id, 'user_id' => $r->user()->id])
            ->delete();
        abort_unless($deleted, 404, 'Notification introuvable.');

        return ApiResponse::success(null, 'Notification supprimée.');
    }
}
