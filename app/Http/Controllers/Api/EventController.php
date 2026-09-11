<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\EventCategory;
use App\Models\Ticket;
use App\Models\TicketOrder;
use App\Models\TicketPayment;
use App\Models\TicketType;
use App\Support\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class EventController extends Controller
{
    public function categories()
    {
        return ApiResponse::success(EventCategory::orderBy('name')->get());
    }

    public function index(Request $r)
    {
        $q = Event::with(['ticketTypes', 'schedules', 'category', 'organizer:id,name,avatar_path'])->where('status', 'published')->where('ends_at', '>=', now());
        if ($r->filled('category')) {
            $q->whereHas('category', fn ($x) => $x->where('slug', $r->category));
        }if ($r->filled('from')) {
            $q->where('starts_at', '>=', $r->from);
        }if ($r->filled('to')) {
            $q->where('starts_at', '<=', $r->to);
        }if ($r->filled('max_price')) {
            $q->whereHas('ticketTypes', fn ($x) => $x->where('price', '<=', $r->max_price));
        }if ($r->filled(['latitude', 'longitude'])) {
            $lat = (float) $r->latitude;
            $lng = (float) $r->longitude;
            $radius = max(1, min(500, (float) $r->input('distance_km', 25)));
            $latDelta = $radius / 111;
            $lngDelta = $radius / (111 * max(.1, cos(deg2rad($lat))));
            $q->whereBetween('latitude', [$lat - $latDelta, $lat + $latDelta])->whereBetween('longitude', [$lng - $lngDelta, $lng + $lngDelta]);
        }

        return ApiResponse::success($q->orderBy('starts_at')->paginate(20));
    }

    public function show(Event $event)
    {
        abort_unless($event->status === 'published', 404);

        return ApiResponse::success($event->load(['ticketTypes', 'schedules', 'category', 'organizer:id,name,avatar_path']));
    }

    public function mine(Request $r)
    {
        return ApiResponse::success(Event::with(['ticketTypes', 'schedules', 'category'])->withCount(['orders as paid_orders_count' => fn ($q) => $q->where('status', 'paid')])->where('organizer_id', $r->user()->id)->latest()->get());
    }

    public function sales(Request $r)
    {
        $events = Event::where('organizer_id', $r->user()->id)->pluck('id');

        return ApiResponse::success(TicketOrder::with(['buyer:id,name,email,phone', 'event:id,title', 'tickets.ticketType'])->whereIn('event_id', $events)->latest()->get());
    }

    public function store(Request $r)
    {
        $d = $this->validated($r);
        $types = $d['ticket_types'];
        $schedules = $d['schedules'];
        unset($d['ticket_types'],$d['schedules'],$d['cover']);
        if ($r->hasFile('cover')) {
            $d['cover_path'] = $r->file('cover')->store('events', 'public');
        }

        return DB::transaction(function () use ($d, $types, $schedules, $r) {
            $e = Event::create([...$d, 'organizer_id' => $r->user()->id]);
            $e->ticketTypes()->createMany($types);
            $e->schedules()->createMany($schedules);

            return ApiResponse::success($e->load(['ticketTypes', 'schedules', 'category']), 'Événement enregistré.', 201);
        });
    }

    public function update(Request $r, Event $event)
    {
        abort_unless($event->organizer_id === $r->user()->id, 403);
        $d = $this->validated($r);
        $types = $d['ticket_types'];
        $schedules = $d['schedules'];
        unset($d['ticket_types'],$d['schedules'],$d['cover']);
        if ($r->hasFile('cover')) {
            $d['cover_path'] = $r->file('cover')->store('events', 'public');
        }

        return DB::transaction(function () use ($event, $d, $types, $schedules) {
            $event->update($d);
            $event->ticketTypes()->whereNotIn('type', collect($types)->pluck('type'))->delete();
            foreach ($types as $type) {
                $event->ticketTypes()->updateOrCreate(['type' => $type['type']], $type);
            }$event->schedules()->delete();
            $event->schedules()->createMany($schedules);

            return ApiResponse::success($event->load(['ticketTypes', 'schedules', 'category']), 'Événement mis à jour.');
        });
    }

    public function archive(Request $r, Event $event)
    {
        abort_unless($event->organizer_id === $r->user()->id, 403);
        abort_if($event->orders()->where('status', 'paid')->exists(), 422, 'Un événement avec des billets vendus ne peut pas être supprimé.');
        $event->update(['status' => 'suspended']);

        return ApiResponse::success($event, 'Événement annulé.');
    }

    private function validated(Request $r): array
    {
        return $r->validate(['event_category_id' => 'required|exists:event_categories,id', 'title' => 'required|string|max:180', 'theme' => 'nullable|string', 'dress_code' => 'nullable|string', 'description' => 'required|string', 'experience' => 'nullable|string', 'place' => 'required|string', 'place_description' => 'nullable|string', 'latitude' => 'nullable|numeric', 'longitude' => 'nullable|numeric', 'starts_at' => 'required|date', 'ends_at' => 'required|date|after:starts_at', 'status' => 'required|in:draft,published', 'cover' => 'nullable|image|max:10240', 'ticket_types' => 'required|array|min:1', 'ticket_types.*.type' => 'required|string', 'ticket_types.*.price' => 'required|numeric|min:0', 'ticket_types.*.capacity' => 'required|integer|min:1', 'schedules' => 'required|array|min:1', 'schedules.*.date' => 'required|date', 'schedules.*.start_time' => 'required|date_format:H:i', 'schedules.*.end_time' => 'required|date_format:H:i']);
    }

    public function order(Request $r, Event $event)
    {
        abort_unless($event->status === 'published', 422, 'La billetterie de cet événement est fermée.');
        abort_if($event->ends_at->isPast(), 422, 'Cet événement est terminé.');
        $d = $r->validate(['ticket_type_id' => 'required|exists:ticket_types,id', 'quantity' => 'required|integer|min:1|max:20', 'payment_method' => 'required|in:mobile_money,bank_card,vimmo_wallet']);

        return DB::transaction(function () use ($r, $event, $d) {
            $type = TicketType::where('event_id', $event->id)->lockForUpdate()->findOrFail($d['ticket_type_id']);
            abort_if($type->sold + $d['quantity'] > $type->capacity, 422, 'Capacité insuffisante.');
            $sandbox = ! app()->environment('production');
            $paid = (float) $type->price === 0.0 || $sandbox;
            $order = TicketOrder::create(['buyer_id' => $r->user()->id, 'event_id' => $event->id, 'reference' => 'ORD-'.strtoupper(Str::random(10)), 'total' => (float) $type->price * $d['quantity'], 'payment_method' => $d['payment_method'], 'status' => $paid ? 'paid' : 'pending']);
            TicketPayment::create(['ticket_order_id' => $order->id, 'reference' => 'TPAY-'.strtoupper(Str::random(12)), 'provider' => $d['payment_method'], 'provider_reference' => $sandbox ? 'SANDBOX-'.strtoupper(Str::random(10)) : null, 'amount' => $order->total, 'currency' => 'XOF', 'status' => $paid ? 'paid' : 'initiated', 'paid_at' => $paid ? now() : null, 'metadata' => ['mode' => $sandbox ? 'sandbox' : 'provider', 'quantity' => $d['quantity'], 'ticket_type_id' => $type->id]]);
            if ($paid) {
                for ($i = 0; $i < $d['quantity']; $i++) {
                    Ticket::create(['ticket_order_id' => $order->id, 'ticket_type_id' => $type->id, 'code' => (string) Str::uuid()]);
                }
                $type->increment('sold', $d['quantity']);
                DB::table('notifications')->insert(['user_id' => $r->user()->id, 'type' => 'ticket', 'title' => 'Billets confirmés', 'body' => 'Votre commande '.$order->reference.' est confirmée.', 'data' => json_encode(['order_id' => $order->id]), 'created_at' => now(), 'updated_at' => now()]);
            }

            return ApiResponse::success($order->load(['payment', 'tickets.ticketType', 'event']), $paid ? 'Paiement confirmé et billets générés.' : 'Paiement initialisé. Confirmez-le auprès du prestataire pour recevoir vos billets.', 201);
        });
    }

    public function tickets(Request $r)
    {
        return ApiResponse::success(TicketOrder::with(['payment', 'tickets.ticketType', 'event'])->where('buyer_id', $r->user()->id)->latest()->get());
    }

    public function cancelOrder(Request $r, TicketOrder $order)
    {
        abort_unless($order->buyer_id === $r->user()->id, 403);
        abort_unless($order->status === 'paid', 422, 'Cette commande ne peut plus être annulée.');
        abort_unless($order->event->starts_at->isFuture(), 422, 'L’événement a déjà commencé.');

        return DB::transaction(function () use ($order) {
            foreach ($order->tickets as $ticket) {
                if ($ticket->status === 'valid') {
                    $ticket->ticketType()->decrement('sold');
                    $ticket->update(['status' => 'cancelled']);
                }
            }$order->update(['status' => 'cancelled']);
            $order->payment?->update(['status' => 'refunded']);

            return ApiResponse::success($order->fresh(['payment', 'tickets']), 'Commande annulée et remboursement enregistré.');
        });
    }

    public function scan(Request $r)
    {
        $d = $r->validate(['code' => 'required|string']);
        $ticket = Ticket::with('order.event')->where('code', $d['code'])->firstOrFail();
        abort_unless($ticket->order->event->organizer_id === $r->user()->id, 403);
        abort_unless($ticket->status === 'valid', 422, 'Billet déjà utilisé ou invalide.');
        $ticket->update(['status' => 'used', 'scanned_at' => now(), 'scanned_by' => $r->user()->id]);

        return ApiResponse::success($ticket, 'Entrée validée.');
    }
}
