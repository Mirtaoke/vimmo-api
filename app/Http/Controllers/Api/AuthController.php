<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Support\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Validation\Rules\Password as PasswordRule;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $data = $request->validate(['first_name' => 'required|string|max:100', 'last_name' => 'required|string|max:100', 'email' => 'required|email|unique:users,email', 'phone' => 'required|string|max:30|unique:users,phone', 'role' => 'required|in:seeker,owner,tenant,organizer', 'password' => ['required', 'confirmed', PasswordRule::min(8)]]);
        $user = User::create([...$data, 'name' => $data['first_name'].' '.$data['last_name'], 'password' => Hash::make($data['password'])]);
        $otp = $this->issueOtp($user);

        return ApiResponse::success(['user' => $user, 'token' => $user->createToken('vimmo-mobile')->plainTextToken, 'sandbox_otp' => app()->environment(['local', 'testing']) ? $otp : null], 'Compte créé. Consultez votre e-mail pour saisir le code de vérification.', 201);
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
        $data = $request->validate(['code' => 'required|digits:6']);
        $otp = DB::table('otp_codes')->where('user_id', $request->user()->id)->where('purpose', 'registration')->whereNull('used_at')->where('expires_at', '>', now())->latest()->first();
        if (! $otp || ! Hash::check($data['code'], $otp->code_hash)) {
            return ApiResponse::error('Code incorrect ou expiré.', 422);
        }
        DB::transaction(function () use ($request, $otp) {
            DB::table('otp_codes')->where('id', $otp->id)->update(['used_at' => now(), 'updated_at' => now()]);
            $request->user()->update([
                'email_verified_at' => now(),
                'phone_verified_at' => now(),
            ]);
        });

        $request->user()->currentAccessToken()?->delete();

        return ApiResponse::success($request->user()->fresh(), 'Adresse e-mail vérifiée. Vous pouvez maintenant vous connecter.');
    }

    public function resendOtp(Request $request)
    {
        $otp = $this->issueOtp($request->user(), 'registration');

        return ApiResponse::success(['sandbox_otp' => app()->environment(['local', 'testing']) ? $otp : null], 'Un nouveau code a été envoyé.');
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
