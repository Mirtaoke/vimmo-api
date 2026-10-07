<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PurgeDemoDataCommandTest extends TestCase
{
    use RefreshDatabase;

    public function test_command_only_removes_the_known_demo_accounts_when_forced(): void
    {
        $demo = User::factory()->create(['email' => 'proprietaire@vimmo.bj', 'role' => 'owner']);
        $real = User::factory()->create(['email' => 'saisie.utilisateur@example.com', 'role' => 'owner']);

        $this->artisan('vimmo:purge-demo-data')->assertSuccessful();
        $this->assertDatabaseHas('users', ['id' => $demo->id]);

        $this->artisan('vimmo:purge-demo-data', ['--force' => true])->assertSuccessful();
        $this->assertDatabaseMissing('users', ['id' => $demo->id]);
        $this->assertDatabaseHas('users', ['id' => $real->id]);
    }
}
