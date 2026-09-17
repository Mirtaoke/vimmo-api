<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Support\ApiResponse;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Carbon;
use Illuminate\Validation\Rules\Password as PasswordRule;
use Symfony\Component\Mailer\Exception\TransportExceptionInterface;
use Throwable;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $data = $request->validate(['first_name' => 'required|string|max:100', 'last_name' => 'required|string|max:100', 'email' => 'required|email', 'phone' => 'required|string|max:30', 'role' => 'required|in:seeker,owner,organizer', 'password' => ['required', 'confirmed', PasswordRule::min(8)]]);
        $data['email'] = strtolower(trim($data['email']));
        $data['phone'] = trim($data['phone']);

        $legacy = User::where('email', $data['email'])->orWhere('phone', $data['phone'])->first();
        if ($legacy && $legacy->email_verified_at) {
            $field = $legacy->email === $data['email'] ? 'email' : 'phone';
            return ApiResponse::error(
                $field === 'email' ? 'Cette adresse e-mail est déjà utilisée.' : 'Ce numéro de téléphone est déjà utilisé.',
                422,
                [$field => [$field === 'email' ? 'Cette adresse e-mail est déjà utilisée.' : 'Ce numéro de téléphone est déjà utilisé.']]
            );
        }
        if ($legacy) {
            $legacy->tokens()->delete();
            DB::table('otp_codes')->where('user_id', $legacy->id)->delete();
            $legacy->delete();
        }

        $pendingPhone = DB::table('pending_registrations')->where('phone', $data['phone'])->where('email', '!=', $data['email'])->first();
        if ($pendingPhone && now()->lt(Carbon::parse($pendingPhone->expires_at))) {
            return ApiResponse::error('Ce numéro est déjà associé à une inscription en cours.', 422, ['phone' => ['Inscription en cours.']]);
        }
        if ($pendingPhone) {
            DB::table('pending_registrations')->where('id', $pendingPhone->id)->delete();
        }

        $otp = (string) random_int(100000, 999999);
        try {
            DB::transaction(function () use ($data, $otp): void {
                DB::table('pending_registrations')->updateOrInsert(
                    ['email' => $data['email']],
                    [
                        'first_name' => $data['first_name'],
                        'last_name' => $data['last_name'],
                        'phone' => $data['phone'],
                        'role' => $data['role'],
                        'password' => Hash::make($data['password']),
                        'otp_hash' => Hash::make($otp),
                        'expires_at' => now()->addMinutes(10),
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]
                );
                $this->sendRegistrationOtp($data['email'], $data['first_name'], $otp);
            });
        } catch (QueryException $exception) {
            Log::error('Échec de la base de données pendant l’inscription provisoire.', [
                'email' => $data['email'],
                'exception' => $exception,
            ]);

            return ApiResponse::error(
                'La préparation de l’inscription a échoué côté base de données. Vérifiez que toutes les migrations ont été exécutées.',
                503
            );
        } catch (TransportExceptionInterface $exception) {
            Log::error('Échec SMTP pendant l’envoi de l’OTP d’inscription.', [
                'email' => $data['email'],
                'exception' => $exception,
            ]);

            return ApiResponse::error(
                'Le serveur e-mail n’a pas pu envoyer le code de vérification. Vérifiez les paramètres SMTP.',
                503
            );
        } catch (Throwable $exception) {
            Log::error('Échec inattendu pendant l’inscription provisoire.', [
                'email' => $data['email'],
                'exception' => $exception,
            ]);

            return ApiResponse::error(
                'L’inscription provisoire n’a pas pu être préparée. Consultez les journaux du serveur.',
                503
            );
        }

        return ApiResponse::success(['email' => $data['email'], 'sandbox_otp' => app()->environment(['local', 'testing']) ? $otp : null], 'Code de vérification envoyé. Le compte sera créé après validation.', 201);
    }

    public function login(Request $request)
    {
        $data = $request->validate(['identifier' => 'required|string', 'password' => 'required|string']);
        $user = User::where('email', $data['identifier'])->orWhere('phone', $data['identifier'])->first();
        if (! $user || ! Hash::check($data['password'], $user->password)) {
            return ApiResponse::error('Identifiants incorrects.', 422);
        }
        if (! $user->is_active) {
            return ApiResponse::error('Compte suspendu.', 403);
        }
        if (! $user->email_verified_at) {
            return ApiResponse::error('Votre adresse e-mail doit être vérifiée avant la connexion.', 403);
        }

        return ApiResponse::success(['user' => $user, 'token' => $user->createToken('vimmo-mobile')->plainTextToken], 'Connexion réussie.');
    }

    public function me(Request $request)
    {
        return ApiResponse::success($request->user());
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()?->delete();

        return ApiResponse::success(null, 'Déconnexion réussie.');
    }

    public function sessions(Request $request)
    {
        return ApiResponse::success($request->user()->tokens()->latest()->get()->map(fn ($token) => ['id' => $token->id, 'name' => $token->name, 'last_used_at' => $token->last_used_at, 'created_at' => $token->created_at, 'current' => $request->user()->currentAccessToken()?->id === $token->id]));
    }

    public function revokeSession(Request $request, int $session)
    {
        $token = $request->user()->tokens()->findOrFail($session);
        $token->delete();

        return ApiResponse::success(null, 'Session déconnectée.');
    }

    public function revokeOtherSessions(Request $request)
    {
        $current = $request->user()->currentAccessToken()?->id;
        $request->user()->tokens()->when($current, fn ($q) => $q->where('id', '!=', $current))->delete();

        return ApiResponse::success(null, 'Toutes les autres sessions ont été déconnectées.');
    }

    public function update(Request $request)
    {
        $data = $request->validate(['first_name' => 'sometimes|string|max:100', 'last_name' => 'sometimes|string|max:100', 'email' => 'sometimes|email|unique:users,email,'.$request->user()->id, 'phone' => 'sometimes|string|max:30|unique:users,phone,'.$request->user()->id, 'preferences' => 'sometimes|array']);
        $request->user()->update($data);

        return ApiResponse::success($request->user()->fresh(), 'Profil mis à jour.');
    }

    public function password(Request $request)
    {
        $data = $request->validate(['current_password' => 'required|current_password', 'password' => ['required', 'confirmed', PasswordRule::min(8)]]);
        $request->user()->update(['password' => Hash::make($data['password'])]);

        return ApiResponse::success(null, 'Mot de passe modifié.');
    }

    public function forgot(Request $request)
    {
        $data = $request->validate(['email' => 'required|email']);
        $user = User::where('email', $data['email'])->first();
        if ($user) {
            $otp = $this->issueOtp($user, 'password_reset');
        }

        return ApiResponse::success(
            ['sandbox_otp' => isset($otp) && app()->environment(['local', 'testing']) ? $otp : null],
            'Si cette adresse correspond à un compte, un code de réinitialisation a été envoyé par e-mail.'
        );
    }

    public function reset(Request $request)
    {
        $data = $request->validate([
            'email' => 'required|email',
            'code' => 'required|digits:6',
            'password' => ['required', 'confirmed', PasswordRule::min(8)],
        ]);
        $user = User::where('email', $data['email'])->first();
        $otp = $user ? DB::table('otp_codes')
            ->where('user_id', $user->id)
            ->where('purpose', 'password_reset')
            ->whereNull('used_at')
            ->where('expires_at', '>', now())
            ->latest()
            ->first() : null;
        if (! $user || ! $otp || ! Hash::check($data['code'], $otp->code_hash)) {
            return ApiResponse::error('Le code est incorrect ou expiré.', 422);
        }
        DB::transaction(function () use ($user, $otp, $data): void {
            DB::table('otp_codes')->where('id', $otp->id)->update(['used_at' => now(), 'updated_at' => now()]);
            $user->forceFill(['password' => Hash::make($data['password'])])->save();
            $user->tokens()->delete();
        });

        return ApiResponse::success(null, 'Mot de passe réinitialisé. Vous pouvez vous connecter.');
    }

    public function verifyOtp(Request $request)
    {
        $data = $request->validate(['email' => 'required|email', 'code' => 'required|digits:6']);
        $pending = DB::table('pending_registrations')->where('email', strtolower(trim($data['email'])))->first();
        if (! $pending || now()->gte(Carbon::parse($pending->expires_at)) || ! Hash::check($data['code'], $pending->otp_hash)) {
            return ApiResponse::error('Code incorrect ou expiré.', 422);
        }
        $user = DB::transaction(function () use ($pending) {
            $user = User::create([
                'first_name' => $pending->first_name,
                'last_name' => $pending->last_name,
                'name' => $pending->first_name.' '.$pending->last_name,
                'email' => $pending->email,
                'phone' => $pending->phone,
                'role' => $pending->role,
                'password' => $pending->password,
                'email_verified_at' => now(),
                'phone_verified_at' => now(),
            ]);
            DB::table('pending_registrations')->where('id', $pending->id)->delete();
            return $user;
        });

        return ApiResponse::success($user, 'Adresse e-mail vérifiée et compte créé. Vous pouvez maintenant vous connecter.');
    }

    public function resendOtp(Request $request)
    {
        $data = $request->validate(['email' => 'required|email']);
        $pending = DB::table('pending_registrations')->where('email', strtolower(trim($data['email'])))->first();
        if (! $pending) {
            return ApiResponse::error('Aucune inscription en attente pour cette adresse e-mail.', 404);
        }
        $otp = (string) random_int(100000, 999999);
        DB::table('pending_registrations')->where('id', $pending->id)->update([
            'otp_hash' => Hash::make($otp),
            'expires_at' => now()->addMinutes(10),
            'updated_at' => now(),
        ]);
        $this->sendRegistrationOtp($pending->email, $pending->first_name, $otp);

        return ApiResponse::success(['sandbox_otp' => app()->environment(['local', 'testing']) ? $otp : null], 'Un nouveau code a été envoyé.');
    }

    private function sendRegistrationOtp(string $email, string $firstName, string $code): void
    {
        Mail::raw("Bonjour {$firstName},\n\nVotre code de vérification VIMMO est : {$code}\n\nCe code expire dans 10 minutes. Votre compte ne sera créé qu'après validation de ce code.", function ($message) use ($email): void {
            $message->to($email)->subject('Votre code de vérification VIMMO');
        });
    }

    private function issueOtp(User $user, string $purpose = 'registration'): string
    {
        $code = (string) random_int(100000, 999999);
        DB::table('otp_codes')->where('user_id', $user->id)->where('purpose', $purpose)->whereNull('used_at')->update(['used_at' => now(), 'updated_at' => now()]);
        DB::table('otp_codes')->insert(['user_id' => $user->id, 'destination' => $user->email, 'purpose' => $purpose, 'code_hash' => Hash::make($code), 'expires_at' => now()->addMinutes(10), 'created_at' => now(), 'updated_at' => now()]);
        $subject = $purpose === 'password_reset' ? 'Réinitialisation de votre mot de passe VIMMO' : 'Votre code de vérification VIMMO';
        $action = $purpose === 'password_reset' ? 'réinitialisation de mot de passe' : 'vérification';
        Mail::raw("Bonjour {$user->first_name},\n\nVotre code de {$action} VIMMO est : {$code}\n\nCe code expire dans 10 minutes. Si vous n'êtes pas à l'origine de cette demande, ignorez ce message.", function ($message) use ($user, $subject): void {
            $message->to($user->email)->subject($subject);
        });

        return $code;
    }
}
