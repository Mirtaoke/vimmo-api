<?php

namespace Tests\Feature;

use App\Models\Event;
use App\Models\EventCategory;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class EventLifecycleApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_paid_order_notifies_buyer_and_organizer_and_generates_tickets(): void
    {
        [$organizer, $buyer, $event, $ticketType] = $this->eventContext();

        $response = $this->actingAs($buyer)->postJson('/api/events/'.$event->id.'/orders', [
            'ticket_type_id' => $ticketType->id,
            'quantity' => 2,
            'payment_method' => 'mobile_money',
        ])->assertCreated()
            ->assertJsonPath('data.status', 'paid')
            ->assertJsonCount(2, 'data.tickets');

        $orderId = $response->json('data.id');
        $this->assertDatabaseHas('notifications', [
            'user_id' => $buyer->id,
            'type' => 'ticket_confirmed',
        ]);
        $this->assertDatabaseHas('notifications', [
            'user_id' => $organizer->id,
            'type' => 'ticket_sale',
        ]);

        $notificationId = (int) $this->actingAs($buyer)
            ->getJson('/api/notifications')
            ->assertOk()
            ->json('data.data.0.id');
        $this->actingAs($buyer)->deleteJson('/api/notifications/'.$notificationId)->assertOk();
        $this->assertDatabaseMissing('notifications', ['id' => $notificationId]);
        $this->assertDatabaseHas('ticket_orders', ['id' => $orderId, 'status' => 'paid']);
        $this->assertDatabaseHas('ticket_types', ['id' => $ticketType->id, 'sold' => 2]);
    }

    public function test_organizer_cannot_remove_or_reduce_an_already_sold_ticket_type(): void
    {
        [$organizer, $buyer, $event, $ticketType] = $this->eventContext();
        $this->actingAs($buyer)->postJson('/api/events/'.$event->id.'/orders', [
            'ticket_type_id' => $ticketType->id,
            'quantity' => 2,
            'payment_method' => 'bank_card',
        ])->assertCreated();

        $payload = $this->eventPayload($event);
        $payload['ticket_types'] = [['type' => 'Standard', 'price' => 5000, 'capacity' => 1]];
        $this->actingAs($organizer)
            ->putJson('/api/organizer/events/'.$event->id, $payload)
            ->assertUnprocessable();

        $payload['ticket_types'] = [['type' => 'VIP', 'price' => 15000, 'capacity' => 1]];
        $this->actingAs($organizer)
            ->putJson('/api/organizer/events/'.$event->id, $payload)
            ->assertUnprocessable();
    }

    public function test_schedule_must_stay_inside_event_period_and_have_a_valid_end_time(): void
    {
        [$organizer, , $event] = $this->eventContext();
        $payload = $this->eventPayload($event);
        $payload['schedules'] = [[
            'date' => now()->addDays(12)->toDateString(),
            'start_time' => '20:00',
            'end_time' => '18:00',
        ]];

        $this->actingAs($organizer)
            ->putJson('/api/organizer/events/'.$event->id, $payload)
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['schedules.0.date', 'schedules.0.end_time']);
    }

    public function test_paid_participant_is_notified_when_event_information_changes(): void
    {
        [$organizer, $buyer, $event, $ticketType] = $this->eventContext();
        $this->actingAs($buyer)->postJson('/api/events/'.$event->id.'/orders', [
            'ticket_type_id' => $ticketType->id,
            'quantity' => 1,
            'payment_method' => 'mobile_money',
        ])->assertCreated();

        $payload = $this->eventPayload($event);
        $payload['place'] = 'Palais des congrès';
        $this->actingAs($organizer)
            ->putJson('/api/organizer/events/'.$event->id, $payload)
            ->assertOk()
            ->assertJsonPath('data.place', 'Palais des congrès');

        $this->assertDatabaseHas('notifications', [
            'user_id' => $buyer->id,
            'type' => 'event_updated',
        ]);
    }

    private function eventContext(): array
    {
        $organizer = User::factory()->create(['role' => 'organizer']);
        $buyer = User::factory()->create(['role' => 'seeker']);
        $category = EventCategory::query()->create(['name' => 'Concert', 'slug' => 'concert']);
        $event = Event::query()->create([
            'organizer_id' => $organizer->id,
            'event_category_id' => $category->id,
            'title' => 'Soirée VIMMO',
            'description' => 'Une soirée test complète.',
            'place' => 'Cotonou',
            'starts_at' => now()->addDays(5)->setTime(18, 0),
            'ends_at' => now()->addDays(5)->setTime(23, 0),
            'status' => 'published',
        ]);
        $event->schedules()->create([
            'date' => now()->addDays(5)->toDateString(),
            'start_time' => '18:00',
            'end_time' => '23:00',
        ]);
        $ticketType = $event->ticketTypes()->create([
            'type' => 'VIP',
            'price' => 15000,
            'capacity' => 20,
        ]);

        return [$organizer, $buyer, $event, $ticketType];
    }

    private function eventPayload(Event $event): array
    {
        return [
            'event_category_id' => $event->event_category_id,
            'title' => $event->title,
            'description' => $event->description,
            'place' => $event->place,
            'starts_at' => $event->starts_at->toIso8601String(),
            'ends_at' => $event->ends_at->toIso8601String(),
            'status' => 'published',
            'ticket_types' => [['type' => 'VIP', 'price' => 15000, 'capacity' => 20]],
            'schedules' => [[
                'date' => $event->starts_at->toDateString(),
                'start_time' => '18:00',
                'end_time' => '23:00',
            ]],
        ];
    }
}
