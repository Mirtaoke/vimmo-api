<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\EventCategory;
use App\Models\Ticket;
use App\Models\TicketOrder;
use App\Models\TicketPayment;
use App\Models\TicketType;
use App\Services\KkiapayPaymentService;
use App\Services\TicketPaymentService;
use App\Support\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class EventController extends Controller
{
    public function __construct(
        private readonly TicketPaymentService $ticketPayments,
        private readonly KkiapayPaymentService $kkiapayPayments,
    ) {}

    public function cover(Event $event)
    {
        abort_unless($event->cover_path, 404, 'Couverture introuvable.');
        $disk = Storage::disk('public');
        abort_unless($disk->exists($event->cover_path), 404, 'Couverture introuvable.');
        $content = $disk->get($event->cover_path);
        $mimeType = $disk->mimeType($event->cover_path) ?: 'image/jpeg';

        return response($content, 200, [
            'Content-Type' => $mimeType,
            'Content-Length' => (string) strlen($content),
            'Content-Disposition' => 'inline',
            'Cache-Control' => 'private, max-age=86400',
        ]);
    }

    public function categories()
    {
        return ApiResponse::success(EventCategory::orderBy('name')->get());
    }

    public function index(Request $r)
    {
        $q = Event::with(['ticketTypes', 'schedules', 'category', 'organizer:id,name,avatar_path'])->where('status', 'published')->where('ends_at', '>=', now());
        if ($r->filled('category')) {
            $q->whereHas('category', fn ($x) => $x->where('slug', $r->category));
        }
        if ($r->filled('from')) {
            $q->where('starts_at', '>=', $r->from);
        }
        if ($r->filled('to')) {
            $q->where('starts_at', '<=', $r->to);
        }
        if ($r->filled('max_price')) {
            $q->whereHas('ticketTypes', fn ($x) => $x->where('price', '<=', $r->max_price));
        }
        if ($r->filled(['latitude', 'longitude'])) {
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
        unset($d['ticket_types'], $d['schedules'], $d['cover']);
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
        unset($d['ticket_types'], $d['schedules'], $d['cover']);
        if ($r->hasFile('cover')) {
            $d['cover_path'] = $r->file('cover')->store('events', 'public');
        }

        return DB::transaction(function () use ($event, $d, $types, $schedules) {
            $lockedEvent = Event::query()->lockForUpdate()->findOrFail($event->id);
            $incomingTypes = collect($types)->pluck('type');
            $soldTypesRemoved = $lockedEvent->ticketTypes()
                ->where('sold', '>', 0)
                ->whereNotIn('type', $incomingTypes)
                ->exists();
            abort_if($soldTypesRemoved, 422, 'Un type de billet déjà vendu ne peut pas être supprimé.');

            foreach ($types as $type) {
                $current = $lockedEvent->ticketTypes()->where('type', $type['type'])->first();
                abort_if(
                    $current && $current->sold > $type['capacity'],
                    422,
                    'La capacité du billet « '.$type['type'].' » ne peut pas être inférieure au nombre déjà vendu.',
                );
            }

            $lockedEvent->update($d);
            $lockedEvent->ticketTypes()->whereNotIn('type', $incomingTypes)->delete();
            foreach ($types as $type) {
                $lockedEvent->ticketTypes()->updateOrCreate(['type' => $type['type']], $type);
            }
            $lockedEvent->schedules()->delete();
            $lockedEvent->schedules()->createMany($schedules);

            $buyerIds = $lockedEvent->orders()
                ->where('status', 'paid')
                ->distinct()
                ->pluck('buyer_id');
            foreach ($buyerIds as $buyerId) {
                DB::table('notifications')->insert([
                    'user_id' => $buyerId,
                    'type' => 'event_updated',
                    'title' => 'Événement mis à jour',
                    'body' => 'Les informations de « '.$lockedEvent->title.' » ont été actualisées.',
                    'data' => json_encode(['event_id' => $lockedEvent->id], JSON_THROW_ON_ERROR),
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }

            return ApiResponse::success($lockedEvent->load(['ticketTypes', 'schedules', 'category']), 'Événement mis à jour.');
        });
    }

    public function status(Request $r, Event $event)
    {
        abort_unless($event->organizer_id === $r->user()->id, 403);
        $data = $r->validate(['status' => 'required|in:draft,published']);
        abort_if(
            $data['status'] === 'draft' && $event->orders()->where('status', 'paid')->exists(),
            422,
            'Un événement ayant des billets vendus ne peut pas repasser en brouillon.',
        );
        $event->update($data);

        return ApiResponse::success($event->fresh(['ticketTypes', 'schedules', 'category']), 'Statut de l’événement mis à jour.');
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
        $data = $r->validate([
            'event_category_id' => 'required|exists:event_categories,id',
            'title' => 'required|string|max:180',
            'theme' => 'nullable|string|max:180',
            'dress_code' => 'nullable|string|max:180',
            'description' => 'required|string',
            'experience' => 'nullable|string',
            'place' => 'required|string|max:255',
            'place_description' => 'nullable|string',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
            'starts_at' => 'required|date',
            'ends_at' => 'required|date|after:starts_at',
            'status' => 'required|in:draft,published',
            'cover' => 'nullable|image|max:10240',
            'ticket_types' => 'required|array|min:1',
            'ticket_types.*.type' => 'required|string|max:100|distinct',
            'ticket_types.*.price' => 'required|numeric|min:0',
            'ticket_types.*.capacity' => 'required|integer|min:1',
            'schedules' => 'required|array|min:1',
            'schedules.*.date' => 'required|date|distinct',
            'schedules.*.start_time' => 'required|date_format:H:i',
            'schedules.*.end_time' => 'required|date_format:H:i',
        ]);

        $startsAt = now()->parse($data['starts_at']);
        $endsAt = now()->parse($data['ends_at']);
        $errors = [];

        foreach ($data['schedules'] as $index => $schedule) {
            $date = now()->parse($schedule['date']);
            if ($date->toDateString() < $startsAt->toDateString() || $date->toDateString() > $endsAt->toDateString()) {
                $errors["schedules.$index.date"] = 'Cette date doit être comprise dans la période de l’événement.';
            }
            if ($schedule['end_time'] <= $schedule['start_time']) {
                $errors["schedules.$index.end_time"] = 'L’heure de fin doit être postérieure à l’heure de début.';
            }
        }

        if ($errors !== []) {
            throw ValidationException::withMessages($errors);
        }

        return $data;
    }

    public function order(Request $r, Event $event)
    {
        abort_unless($event->status === 'published', 422, 'La billetterie de cet événement est fermée.');
        abort_if($event->ends_at->isPast(), 422, 'Cet événement est terminé.');
        $d = $r->validate([
            'ticket_type_id' => 'required|exists:ticket_types,id',
            'quantity' => 'required|integer|min:1|max:20',
            'payment_method' => 'required|in:kkiapay',
        ]);

        return DB::transaction(function () use ($r, $event, $d) {
            $type = TicketType::where('event_id', $event->id)->lockForUpdate()->findOrFail($d['ticket_type_id']);
            abort_if($type->sold + $d['quantity'] > $type->capacity, 422, 'Capacité insuffisante.');
            $paid = (float) $type->price === 0.0;
            $order = TicketOrder::create(['buyer_id' => $r->user()->id, 'event_id' => $event->id, 'reference' => 'ORD-'.strtoupper(Str::random(10)), 'total' => (float) $type->price * $d['quantity'], 'payment_method' => $d['payment_method'], 'status' => 'pending']);
            $payment = TicketPayment::create(['ticket_order_id' => $order->id, 'reference' => 'TPAY-'.strtoupper(Str::random(12)), 'provider' => $d['payment_method'], 'provider_reference' => null, 'amount' => $order->total, 'currency' => 'XOF', 'status' => 'initiated', 'paid_at' => null, 'metadata' => ['quantity' => $d['quantity'], 'ticket_type_id' => $type->id]]);
            if ($paid) {
                $this->ticketPayments->confirm($payment, 'FREE-'.$order->reference);
            }

            $transaction = $paid
                ? null
                : $this->kkiapayPayments->createIntent($payment, $r->user(), (float) $order->total);
            $data = $order->fresh(['payment.kkiapayTransaction', 'tickets.ticketType', 'event'])->toArray();
            $data['checkout'] = $transaction === null ? null : $this->kkiapayPayments->checkout($transaction);

            return ApiResponse::success($data, $paid ? 'Billets gratuits générés.' : 'Commande créée. Finalisez le paiement avec KKiaPay.', 201);
        });
    }

    public function tickets(Request $r)
    {
        return ApiResponse::success(TicketOrder::with(['payment.kkiapayTransaction', 'tickets.ticketType', 'event'])->where('buyer_id', $r->user()->id)->latest()->get());
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
            }
            $order->update(['status' => 'cancelled']);
            $order->payment?->update(['status' => 'refunded']);
            DB::table('notifications')->insert([
                'user_id' => $order->event->organizer_id,
                'type' => 'ticket_cancelled',
                'title' => 'Commande annulée',
                'body' => 'La commande '.$order->reference.' a été annulée.',
                'data' => json_encode(['order_id' => $order->id, 'event_id' => $order->event_id], JSON_THROW_ON_ERROR),
                'created_at' => now(),
                'updated_at' => now(),
            ]);

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
        DB::table('notifications')->insert([
            'user_id' => $ticket->order->buyer_id,
            'type' => 'ticket_scanned',
            'title' => 'Entrée validée',
            'body' => 'Votre billet pour « '.$ticket->order->event->title.' » vient d’être validé.',
            'data' => json_encode(['order_id' => $ticket->order->id, 'event_id' => $ticket->order->event_id], JSON_THROW_ON_ERROR),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return ApiResponse::success($ticket, 'Entrée validée.');
    }
}
