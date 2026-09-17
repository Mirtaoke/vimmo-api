<?php

namespace Tests\Feature;

use App\Mail\PatrimonySharedMail;
use App\Models\Media;
use App\Models\Property;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class PatrimonySharingApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_unknown_email_is_rejected_and_no_share_is_created(): void
    {
        $this->seed();
        $owner = User::where('email', 'proprietaire@vimmo.bj')->firstOrFail();
        $property = Property::where('owner_id', $owner->id)->where('is_private', true)->firstOrFail();
        $before = \DB::table('asset_shares')->count();
        $this->actingAs($owner)->postJson('/api/patrimony/'.$property->id.'/shares', ['name' => 'Inconnu', 'email' => 'adresse.absente@vimmo.bj', 'permission' => 'view'])->assertStatus(422)->assertJsonPath('message', 'Aucun compte VIMMO n’existe avec cette adresse e-mail. Demandez au proche de créer son compte ou renseignez une autre adresse.');
        $this->assertSame($before, \DB::table('asset_shares')->count());
    }

    public function test_existing_user_receives_shared_property(): void
    {
        Mail::fake();
        $this->seed();
        $owner = User::where('email', 'proprietaire@vimmo.bj')->firstOrFail();
        $recipient = User::where('email', 'chercheur@vimmo.bj')->firstOrFail();
        $property = Property::where('owner_id', $owner->id)->where('is_private', true)->firstOrFail();
        $this->actingAs($owner)->postJson('/api/patrimony/'.$property->id.'/shares', ['name' => $recipient->name, 'email' => $recipient->email, 'permission' => 'documents'])->assertCreated();
        $this->actingAs($recipient)->getJson('/api/patrimony/shared-with-me')->assertOk()->assertJsonFragment(['id' => $property->id, 'share_permission' => 'documents']);
        Mail::assertSent(PatrimonySharedMail::class, fn (PatrimonySharedMail $mail): bool => $mail->hasTo($recipient->email)
            && $mail->propertyName === $property->name
            && $mail->permissionLabel === 'consultation du bien et de ses documents');
    }

    public function test_view_permission_cannot_download_a_private_document(): void
    {
        $this->seed();
        $owner = User::where('email', 'proprietaire@vimmo.bj')->firstOrFail();
        $recipient = User::where('email', 'chercheur@vimmo.bj')->firstOrFail();
        $property = Property::where('owner_id', $owner->id)->where('is_private', true)->firstOrFail();
        $media = Media::where('mediable_type', Property::class)->where('mediable_id', $property->id)->where('collection', 'documents')->firstOrFail();
        $this->actingAs($owner)->postJson('/api/patrimony/'.$property->id.'/shares', ['name' => $recipient->name, 'email' => $recipient->email, 'permission' => 'view'])->assertCreated();
        $this->actingAs($recipient)->get('/api/media/'.$media->id.'/download')->assertForbidden();
    }
}
