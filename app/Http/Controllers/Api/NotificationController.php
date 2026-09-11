<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class NotificationController extends Controller
{
    public function index(Request $r)
    {
        return ApiResponse::success(DB::table('notifications')->where('user_id', $r->user()->id)->latest()->paginate(30));
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
}
