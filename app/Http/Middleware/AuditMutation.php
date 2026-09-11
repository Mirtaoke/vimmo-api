<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\Response;

class AuditMutation
{
    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);
        if ($request->user() && in_array($request->method(), ['POST', 'PUT', 'PATCH', 'DELETE'], true)) {
            $route = $request->route();
            $parameters = collect($route?->parameters() ?? [])->map(fn ($value) => is_object($value) && isset($value->id) ? $value->id : $value)->all();
            DB::table('audit_logs')->insert(['user_id' => $request->user()->id, 'action' => $request->method().' '.($route?->uri() ?? $request->path()), 'auditable_type' => null, 'auditable_id' => null, 'before' => null, 'after' => json_encode(['status' => $response->getStatusCode(), 'parameters' => $parameters]), 'ip_address' => $request->ip(), 'user_agent' => mb_substr((string) $request->userAgent(), 0, 1000), 'created_at' => now(), 'updated_at' => now()]);
        }

return $response;
    }
}
