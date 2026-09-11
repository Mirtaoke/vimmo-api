<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        $users = [
            ['Koffi', 'Ahouansou', 'proprietaire@vimmo.bj', '97000001', 'owner'],
            ['Mireille', 'Adjovi', 'mireille.proprietaire@vimmo.bj', '97000005', 'owner'],
            ['Arnaud', 'Hounkpatin', 'arnaud.proprietaire@vimmo.bj', '97000006', 'owner'],
            ['Aïcha', 'Mensah', 'locataire@vimmo.bj', '97000002', 'tenant'],
            ['Sonia', 'Dossou', 'sonia.locataire@vimmo.bj', '97000007', 'tenant'],
            ['Kevin', 'Adande', 'kevin.locataire@vimmo.bj', '97000008', 'tenant'],
            ['Nadia', 'Kiki', 'chercheur@vimmo.bj', '97000003', 'seeker'],
            ['Ruth', 'Soglo', 'ruth.chercheur@vimmo.bj', '97000009', 'seeker'],
            ['Lionel', 'Gandonou', 'lionel.chercheur@vimmo.bj', '97000010', 'seeker'],
            ['VIMMO', 'Events', 'events@vimmo.bj', '97000004', 'organizer'],
            ['Grâce', 'Tonato', 'grace.events@vimmo.bj', '97000011', 'organizer'],
            ['Studio', 'Nokoué', 'nokoue.events@vimmo.bj', '97000012', 'organizer'],
        ];

        foreach ($users as $user) {
            User::updateOrCreate(
                ['email' => $user[2]],
                [
                    'name' => $user[0].' '.$user[1],
                    'first_name' => $user[0],
                    'last_name' => $user[1],
                    'phone' => $user[3],
                    'role' => $user[4],
                    'password' => Hash::make('password'),
                    'is_active' => true,
                    'email_verified_at' => now(),
                    'phone_verified_at' => now(),
                ],
            );
        }
    }
}
