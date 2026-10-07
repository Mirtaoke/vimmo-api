<?php

namespace Tests\Feature;

use App\Mail\PatrimonySharedMail;
use App\Models\Media;
use App\Models\Property;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class PatrimonySharingApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_unknown_email_creates_a_family_account_and_share(): void
    {
        Mail::fake();
        $this->seed();
        $owner = User::where('email', 'proprietaire@vimmo.bj')->firstOrFail();
        $property = $this->privateProperty($owner);
        $this->actingAs($owner)->postJson('/api/patrimony/'.$property->id.'/shares', ['name' => 'Clarisse Inconnue', 'email' => 'adresse.absente@vimmo.bj', 'permission' => 'view'])->assertCreated();
        $recipient = User::where('email', 'adresse.absente@vimmo.bj')->firstOrFail();
        $this->assertSame('family_member', $recipient->role);
        $this->assertNull($recipient->email_verified_at);
        $this->assertDatabaseHas('asset_shares', ['property_id' => $property->id, 'shared_with_id' => $recipient->id]);
        $this->assertDatabaseHas('otp_codes', ['user_id' => $recipient->id, 'purpose' => 'family_activation']);
        $shareId = \DB::table('asset_shares')->where('property_id', $property->id)->where('shared_with_id', $recipient->id)->value('id');
        $this->actingAs($owner)->deleteJson('/api/patrimony/shares/'.$shareId)->assertOk();
        $this->assertModelMissing($recipient);
    }

    public function test_existing_user_receives_shared_property(): void
    {
        Mail::fake();
        $this->seed();
        $owner = User::where('email', 'proprietaire@vimmo.bj')->firstOrFail();
        $recipient = User::where('email', 'famille@vimmo.bj')->firstOrFail();
        $property = $this->privateProperty($owner);
        $this->actingAs($owner)->postJson('/api/patrimony/'.$property->id.'/shares', ['name' => $recipient->name, 'email' => $recipient->email, 'permission' => 'documents'])->assertCreated();
        $this->actingAs($recipient)->getJson('/api/patrimony/shared-with-me')->assertOk()->assertJsonFragment(['id' => $property->id, 'share_permission' => 'documents']);
        Mail::assertSent(PatrimonySharedMail::class, fn (PatrimonySharedMail $mail): bool => $mail->hasTo($recipient->email)
            && $mail->propertyName === $property->name
            && $mail->permissionLabel === 'consultation du bien et de ses documents');

        $this->actingAs($owner)->getJson('/api/patrimony')
            ->assertOk()
            ->assertJsonFragment([
                'property_id' => $property->id,
                'email' => $recipient->email,
                'permission' => 'documents',
            ]);
    }

    public function test_manage_permission_can_update_shared_property_but_view_cannot(): void
    {
        Mail::fake();
        $this->seed();
        $owner = User::where('email', 'proprietaire@vimmo.bj')->firstOrFail();
        $manager = User::where('email', 'famille@vimmo.bj')->firstOrFail();
        $viewer = User::factory()->create(['role' => 'family_member']);
        $property = $this->privateProperty($owner);

        $this->actingAs($owner)->postJson('/api/patrimony/'.$property->id.'/shares', [
            'name' => $manager->name,
            'email' => $manager->email,
            'permission' => 'manage',
        ])->assertCreated();
        $this->actingAs($owner)->postJson('/api/patrimony/'.$property->id.'/shares', [
            'name' => $viewer->name,
            'email' => $viewer->email,
            'permission' => 'view',
        ])->assertCreated();

        $this->actingAs($manager)->putJson('/api/patrimony/'.$property->id, [
            'description' => 'Description complétée par le gestionnaire familial.',
        ])->assertOk();
        $this->actingAs($viewer)->putJson('/api/patrimony/'.$property->id, [
            'description' => 'Modification interdite',
        ])->assertForbidden();
    }

    public function test_view_permission_cannot_download_a_private_document(): void
    {
        $this->seed();
        $owner = User::where('email', 'proprietaire@vimmo.bj')->firstOrFail();
        $recipient = User::where('email', 'famille@vimmo.bj')->firstOrFail();
        $property = $this->privateProperty($owner);
        Media::create([
            'user_id' => $owner->id,
            'mediable_type' => Property::class,
            'mediable_id' => $property->id,
            'collection' => 'documents',
            'label' => 'Document privé',
            'disk' => 'private',
            'path' => 'tests/document-prive.pdf',
            'mime_type' => 'application/pdf',
            'size' => 10,
            'metadata' => ['original_name' => 'document-prive.pdf'],
        ]);
        $media = Media::where('mediable_type', Property::class)->where('mediable_id', $property->id)->where('collection', 'documents')->firstOrFail();
        $this->actingAs($owner)->postJson('/api/patrimony/'.$property->id.'/shares', ['name' => $recipient->name, 'email' => $recipient->email, 'permission' => 'view'])->assertCreated();
        $this->actingAs($recipient)->get('/api/media/'.$media->id.'/download')->assertForbidden();
    }

    public function test_owner_can_stream_a_private_patrimony_document(): void
    {
        Storage::fake('private');
        $owner = User::factory()->create(['role' => 'owner']);
        $property = Property::create([
            'owner_id' => $owner->id,
            'name' => 'Parcelle familiale',
            'type' => 'Parcelle',
            'is_private' => true,
        ]);
        Storage::disk('private')->put('vault/documents/titre.pdf', '%PDF-document-test');
        $media = Media::create([
            'user_id' => $owner->id,
            'mediable_type' => Property::class,
            'mediable_id' => $property->id,
            'collection' => 'documents',
            'label' => 'Titre de propriété',
            'disk' => 'private',
            'path' => 'vault/documents/titre.pdf',
            'mime_type' => 'application/pdf',
            'size' => 18,
            'metadata' => ['original_name' => 'titre-de-propriete.pdf'],
        ]);

        $this->actingAs($owner)->get('/api/media/'.$media->id.'/download')
            ->assertOk()
            ->assertHeader('content-type', 'application/pdf')
            ->assertDownload('titre-de-propriete.pdf');
    }

    private function privateProperty(User $owner): Property
    {
        return Property::create([
            'owner_id' => $owner->id,
            'name' => 'Bien familial de test',
            'type' => 'Maison',
            'is_private' => true,
        ]);
    }
}
