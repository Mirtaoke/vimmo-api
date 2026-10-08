<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Mail\OneTimeCodeMail;
use App\Models\User;
use App\Support\ApiResponse;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Validation\Rules\Password as PasswordRule;
use Symfony\Component\Mailer\Exception\TransportExceptionInterface;
use Throwable;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $request->merge([
            'email' => strtolower(trim((string) $request->input('email'))),
            'phone' => preg_replace('/[\s().-]+/', '', trim((string) $request->input('phone'))),
        ]);
        $data = $request->validate(['first_name' => 'required|string|max:100', 'last_name' => 'required|string|max:100', 'email' => 'required|email', 'phone' => 'required|string|max:30', 'role' => 'required|in:seeker,owner,organizer,family_member', 'password' => ['required', 'confirmed', PasswordRule::min(8)]]);
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
            DB::table('pending_registrations')->updateOrInsert(
                ['email' => $data['email']],
                [
                    'first_name' => $data['first_name'],
                    'last_name' => $data['last_name'],
                    'phone' => $data['phone'],
                    'role' => $data['role'],
                    'password' => Hash::make($data['password']),
                    'otp_hash' => Hash::make($otp),
                    'resend_count' => 0,
                    'last_sent_at' => null,
                    'expires_at' => now()->addMinutes(10),
                    'created_at' => now(),
                    'updated_at' => now(),
                ]
            );
        } catch (QueryException $exception) {
            Log::error('Échec de la base de données pendant l’inscription provisoire.', [
                'email' => $data['email'],
                'exception' => $exception,
            ]);

            return ApiResponse::error(
                'La préparation de l’inscription a échoué côté base de données. Vérifiez que toutes les migrations ont été exécutées.',
                503
            );
        }

        try {
            $this->sendRegistrationOtp($data['email'], $data['first_name'], $otp);
            DB::table('pending_registrations')
                ->where('email', $data['email'])
                ->update(['last_sent_at' => now(), 'updated_at' => now()]);
        } catch (TransportExceptionInterface $exception) {
            Log::error('Échec SMTP pendant l’envoi de l’OTP d’inscription.', [
                'email' => $data['email'],
                'mailer' => config('mail.default'),
                'host' => config('mail.mailers.smtp.host'),
                'error' => $exception->getMessage(),
            ]);

            return ApiResponse::error(
                'Le code n’a pas pu être envoyé par e-mail. Réessayez ou vérifiez la configuration SMTP.',
                503,
                ['email_delivery' => ['Échec de l’envoi du code de vérification.']]
            );
        } catch (Throwable $exception) {
            Log::error('Échec inattendu pendant l’envoi de l’OTP d’inscription.', [
                'email' => $data['email'],
                'error' => $exception->getMessage(),
            ]);

            return ApiResponse::error(
                'Le code n’a pas pu être envoyé par e-mail. Réessayez dans un instant.',
                503,
                ['email_delivery' => ['Échec de l’envoi du code de vérification.']]
            );
        }

        return ApiResponse::success([
            'email' => $data['email'],
            'sandbox_otp' => app()->environment(['local', 'testing']) ? $otp : null,
            'expires_in' => 600,
            'resend_available_in' => 60,
            'remaining_resends' => 5,
        ], 'Code de vérification envoyé. Le compte sera créé après validation.', 201);
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
            return ApiResponse::error('Votre accès familial doit être activé avant la connexion.', 403, ['requires_family_activation' => $user->role === 'family_member', 'email' => $user->email]);
        }

        // Compatibilité avec les comptes créés avant l'ajout des champs séparés.
        if (blank($user->first_name) || blank($user->last_name)) {
            $parts = preg_split('/\s+/', trim((string) $user->name), 2) ?: [];
            $user->forceFill([
                'first_name' => filled($user->first_name) ? $user->first_name : ($parts[0] ?? null),
                'last_name' => filled($user->last_name) ? $user->last_name : ($parts[1] ?? null),
            ])->save();
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
        $firstName = $data['first_name'] ?? $request->user()->first_name;
        $lastName = $data['last_name'] ?? $request->user()->last_name;
        if (array_key_exists('first_name', $data) || array_key_exists('last_name', $data)) {
            $data['name'] = trim($firstName.' '.$lastName);
        }
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
        $data = $request->validate(['email' => 'required|email', 'resend' => 'sometimes|boolean']);
        $email = strtolower(trim($data['email']));
        $user = User::where('email', $email)->first();
        if (! $user) {
            return ApiResponse::error(
                'Aucun compte n’est associé à cette adresse e-mail.',
                404,
                ['email' => ['Adresse e-mail inconnue.']]
            );
        }
        if (! $user->email_verified_at) {
            return ApiResponse::error('Activez d’abord votre compte familial avec le code reçu par e-mail.', 422, ['requires_family_activation' => $user->role === 'family_member']);
        }
        $resendCount = 0;
        if ($data['resend'] ?? false) {
            $current = DB::table('otp_codes')
                ->where('user_id', $user->id)
                ->where('purpose', 'password_reset')
                ->whereNull('used_at')
                ->latest()
                ->first();
            if ($current) {
                $resendCount = (int) $current->resend_count;
                if ($resendCount >= 5) {
                    return ApiResponse::error('Le nombre maximal de renvois a été atteint. Recommencez la récupération.', 429, ['remaining_resends' => 0]);
                }
                $availableAt = Carbon::parse($current->last_sent_at ?? $current->created_at)->addSeconds(60);
                if (now()->lt($availableAt)) {
                    return ApiResponse::error('Veuillez patienter avant de demander un nouveau code.', 429, [
                        'retry_after' => max(1, (int) ceil(now()->diffInSeconds($availableAt))),
                        'remaining_resends' => 5 - $resendCount,
                    ]);
                }
                $resendCount++;
            }
        }
        $otp = $this->issueOtp($user, 'password_reset', $resendCount);

        return ApiResponse::success(
            [
                'sandbox_otp' => isset($otp) && app()->environment(['local', 'testing']) ? $otp : null,
                'expires_in' => 600,
                'resend_available_in' => 60,
                'remaining_resends' => max(0, 5 - $resendCount),
            ],
            'Un code de réinitialisation a été envoyé par e-mail.'
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

    public function activateFamily(Request $request)
    {
        $data = $request->validate([
            'email' => 'required|email',
            'code' => 'required|digits:6',
            'password' => ['required', 'confirmed', PasswordRule::min(8)],
        ]);
        $user = User::where('email', strtolower(trim($data['email'])))->where('role', 'family_member')->first();
        $otp = $user ? DB::table('otp_codes')->where('user_id', $user->id)->where('purpose', 'family_activation')->whereNull('used_at')->where('expires_at', '>', now())->latest()->first() : null;
        if (! $user || ! $otp || ! Hash::check($data['code'], $otp->code_hash)) {
            return ApiResponse::error('Le code d’activation est incorrect ou expiré.', 422);
        }
        DB::transaction(function () use ($user, $otp, $data): void {
            DB::table('otp_codes')->where('id', $otp->id)->update(['used_at' => now(), 'updated_at' => now()]);
            $user->forceFill([
                'password' => Hash::make($data['password']),
                'email_verified_at' => now(),
                'is_active' => true,
            ])->save();
        });

        return ApiResponse::success(null, 'Votre espace familial est activé. Vous pouvez vous connecter.');
    }

    public function resendFamilyActivation(Request $request)
    {
        $data = $request->validate(['email' => 'required|email']);
        $user = User::where('email', strtolower(trim($data['email'])))->where('role', 'family_member')->whereNull('email_verified_at')->first();
        abort_unless($user, 404, 'Aucun accès familial en attente pour cette adresse.');
        $current = DB::table('otp_codes')->where('user_id', $user->id)->where('purpose', 'family_activation')->whereNull('used_at')->latest()->first();
        $resendCount = (int) ($current->resend_count ?? 0);
        abort_if($resendCount >= 5, 429, 'Le nombre maximal de renvois a été atteint.');
        if ($current?->last_sent_at) {
            $availableAt = Carbon::parse($current->last_sent_at)->addSeconds(60);
            if (now()->lt($availableAt)) {
                return ApiResponse::error('Veuillez patienter avant de demander un nouveau code.', 429, ['retry_after' => max(1, (int) ceil(now()->diffInSeconds($availableAt)))]);
            }
        }
        $code = $this->issueOtp($user, 'family_activation', $resendCount + 1);

        return ApiResponse::success([
            'sandbox_otp' => app()->environment(['local', 'testing']) ? $code : null,
            'expires_in' => 600,
            'resend_available_in' => 60,
            'remaining_resends' => max(0, 4 - $resendCount),
        ], 'Un nouveau code d’activation a été envoyé.');
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
        $remainingResends = max(0, 5 - (int) $pending->resend_count);
        if ($remainingResends === 0) {
            return ApiResponse::error(
                'Le nombre maximal de renvois a été atteint. Recommencez l’inscription.',
                429,
                ['remaining_resends' => 0]
            );
        }
        if ($pending->last_sent_at) {
            $availableAt = Carbon::parse($pending->last_sent_at)->addSeconds(60);
            if (now()->lt($availableAt)) {
                return ApiResponse::error(
                    'Veuillez patienter avant de demander un nouveau code.',
                    429,
                    [
                        'retry_after' => max(1, (int) ceil(now()->diffInSeconds($availableAt))),
                        'remaining_resends' => $remainingResends,
                    ]
                );
            }
        }
        $otp = (string) random_int(100000, 999999);
        try {
            $this->sendRegistrationOtp($pending->email, $pending->first_name, $otp);
            DB::table('pending_registrations')->where('id', $pending->id)->update([
                'otp_hash' => Hash::make($otp),
                'resend_count' => (int) $pending->resend_count + 1,
                'last_sent_at' => now(),
                'expires_at' => now()->addMinutes(10),
                'updated_at' => now(),
            ]);
        } catch (TransportExceptionInterface $exception) {
            Log::error('Échec SMTP pendant le renvoi de l’OTP d’inscription.', [
                'email' => $pending->email,
                'mailer' => config('mail.default'),
                'host' => config('mail.mailers.smtp.host'),
                'error' => $exception->getMessage(),
            ]);

            return ApiResponse::error(
                'Le nouveau code n’a pas pu être envoyé par e-mail. L’ancien code reste valable jusqu’à son expiration.',
                503,
                ['email_delivery' => ['Échec du renvoi du code de vérification.']]
            );
        }

        return ApiResponse::success([
            'sandbox_otp' => app()->environment(['local', 'testing']) ? $otp : null,
            'expires_in' => 600,
            'resend_available_in' => 60,
            'remaining_resends' => $remainingResends - 1,
        ], 'Un nouveau code a été envoyé. L’ancien code n’est plus valable.');
    }

    private function sendRegistrationOtp(string $email, string $firstName, string $code): void
    {
        Mail::to($email)->send(new OneTimeCodeMail($firstName, $code));
    }

    private function issueOtp(User $user, string $purpose = 'registration', int $resendCount = 0): string
    {
        $code = (string) random_int(100000, 999999);
        DB::table('otp_codes')->where('user_id', $user->id)->where('purpose', $purpose)->whereNull('used_at')->update(['used_at' => now(), 'updated_at' => now()]);
        DB::table('otp_codes')->insert(['user_id' => $user->id, 'destination' => $user->email, 'purpose' => $purpose, 'code_hash' => Hash::make($code), 'resend_count' => $resendCount, 'last_sent_at' => now(), 'expires_at' => now()->addMinutes(10), 'created_at' => now(), 'updated_at' => now()]);
        Mail::to($user->email)->send(
            new OneTimeCodeMail($user->first_name ?: $user->name, $code, $purpose)
        );

        return $code;
    }
}
