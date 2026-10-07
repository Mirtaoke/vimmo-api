<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

#[Signature('vimmo:purge-demo-data {--force : Supprimer définitivement les comptes et données de démonstration}')]
#[Description('Supprime uniquement les anciens comptes de démonstration et leurs données liées')]
class PurgeDemoData extends Command
{
    public function handle(): int
    {
        $emails = [
            'proprietaire@vimmo.bj',
            'mireille.proprietaire@vimmo.bj',
            'arnaud.proprietaire@vimmo.bj',
            'locataire@vimmo.bj',
            'sonia.locataire@vimmo.bj',
            'kevin.locataire@vimmo.bj',
            'chercheur@vimmo.bj',
            'ruth.chercheur@vimmo.bj',
            'lionel.chercheur@vimmo.bj',
            'events@vimmo.bj',
            'grace.events@vimmo.bj',
            'nokoue.events@vimmo.bj',
            'famille@vimmo.bj',
        ];
        $users = User::query()->whereIn('email', $emails)->get(['id', 'name', 'email']);

        if ($users->isEmpty()) {
            $this->info('Aucune donnée de démonstration à supprimer.');

            return self::SUCCESS;
        }

        $this->table(
            ['ID', 'Utilisateur', 'E-mail'],
            $users->map(fn (User $user): array => [$user->id, $user->name, $user->email])->all(),
        );

        if (! $this->option('force')) {
            $this->warn('Aucune suppression effectuée. Relancez avec --force après avoir vérifié cette liste.');

            return self::SUCCESS;
        }

        DB::transaction(function () use ($users, $emails): void {
            $userIds = $users->pluck('id');

            DB::table('personal_access_tokens')
                ->where('tokenable_type', User::class)
                ->whereIn('tokenable_id', $userIds)
                ->delete();
            DB::table('sessions')->whereIn('user_id', $userIds)->delete();
            DB::table('password_reset_tokens')->whereIn('email', $emails)->delete();
            DB::table('pending_registrations')->whereIn('email', $emails)->delete();
            User::query()->whereIn('id', $userIds)->delete();
        });

        $this->info($users->count().' compte(s) de démonstration et leurs données liées ont été supprimés.');

        return self::SUCCESS;
    }
}
