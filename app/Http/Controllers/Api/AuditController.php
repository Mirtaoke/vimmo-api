<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AuditController extends Controller
{
    public function index(Request $r)
    {
        $query = DB::table('audit_logs')->where('user_id', $r->user()->id);
        if ($r->filled('action')) {
            $query->where('action', 'like', '%'.$r->action.'%');
        }

return ApiResponse::success($query->latest()->paginate(50));
    }
}
