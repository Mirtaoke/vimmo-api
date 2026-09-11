import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/auth/auth_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/role_extensions.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/esge_ui.dart';
import '../auth/role_selection_page.dart';
import 'change_password_page.dart';
import 'personal_information_page.dart';
import 'profile_option_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: EsgeGlowBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 105),
            children: [
              const BrandMark(compact: true),
              const SizedBox(height: 20),
              _identityCard(context, user),
              const SizedBox(height: 20),
              _sectionTitle('Informations du compte'),
              const SizedBox(height: 9),
              _accountGrid(user),
              const SizedBox(height: 9),
              _setting(
                'Informations personnelles',
                'Photo, nom, téléphone et adresse e-mail',
                Icons.person_outline_rounded,
                AppColors.indigo,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PersonalInformationPage(),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _sectionTitle('Accès & traçabilité'),
              const SizedBox(height: 9),
              _setting(
                'Permissions',
                'Droits accordés à votre rôle',
                Icons.admin_panel_settings_outlined,
                AppColors.orange,
                () => _openOption(
                  context,
                  'Permissions',
                  Icons.admin_panel_settings_outlined,
                  user.permissions,
                  AppColors.orange,
                  ProfileOptionKind.permissions,
                ),
              ),
              _setting(
                'Historique de connexion',
                'Dernière connexion aujourd’hui à 08:42',
                Icons.history_rounded,
                AppColors.tealDark,
                () => _openOption(
                  context,
                  'Historique de connexion',
                  Icons.history_rounded,
                  const [
                    'Connexion mobile Android',
                    'Connexion Web professionnelle',
                    'Connexion mobile Android',
                  ],
                  AppColors.tealDark,
                  ProfileOptionKind.history,
                ),
              ),
              _setting(
                'Appareils & sessions',
                '2 appareils actuellement autorisés',
                Icons.devices_outlined,
                AppColors.indigo,
                () => _openOption(
                  context,
                  'Appareils & sessions',
                  Icons.devices_outlined,
                  const ['Téléphone actuel', 'Ordinateur professionnel'],
                  AppColors.indigo,
                  ProfileOptionKind.sessions,
                ),
              ),
              const SizedBox(height: 14),
              _sectionTitle('Sécurité & notifications'),
              const SizedBox(height: 9),
              _setting(
                'Changer le mot de passe',
                'Renouveler vos identifiants de connexion',
                Icons.lock_outline_rounded,
                AppColors.plum,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
                ),
              ),
              _setting(
                'Notifications',
                'Alertes métier et demandes de validation',
                Icons.notifications_none_rounded,
                AppColors.coral,
                () => _openOption(
                  context,
                  'Notifications',
                  Icons.notifications_none_rounded,
                  const [
                    'Alertes métier',
                    'Demandes de validation',
                    'Rapports hebdomadaires',
                  ],
                  AppColors.coral,
                  ProfileOptionKind.toggles,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  context.read<AuthCubit>().signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RoleSelectionPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.logout_rounded, color: AppColors.red),
                label: const Text('Déconnexion'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _identityCard(BuildContext context, UserModel user) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF182B55), Color(0xFF5968B0)],
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: AppColors.indigo.withValues(alpha: .24),
          blurRadius: 26,
          offset: const Offset(0, 13),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 62,
          height: 62,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .15),
            borderRadius: BorderRadius.circular(19),
          ),
          child: user.photoUrl == null
              ? Icon(user.role.icon, color: Colors.white, size: 28)
              : Image.file(
                  File(user.photoUrl!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Icon(user.role.icon, color: Colors.white, size: 28),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${user.jobTitle} • ${user.service}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 9.5),
              ),
              const SizedBox(height: 7),
              const EsgeStatusChip('Compte actif', color: Color(0xFFA8F0C5)),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Modifier les informations personnelles',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PersonalInformationPage()),
          ),
          icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
        ),
      ],
    ),
  );

  Widget _accountGrid(UserModel user) {
    final items = <(String, String, IconData, Color)>[
      ('Fonction', user.jobTitle, Icons.badge_outlined, AppColors.indigo),
      ('Service', user.service, Icons.apartment_rounded, AppColors.orange),
      ('Identifiant', user.identifier, Icons.pin_outlined, AppColors.plum),
      (
        'Statut',
        user.isActive ? 'Actif' : 'Suspendu',
        Icons.verified_outlined,
        AppColors.tealDark,
      ),
      ('Date d’entrée', user.entryDate, Icons.event_outlined, AppColors.coral),
      (
        'Responsable',
        user.managerName,
        Icons.account_tree_outlined,
        AppColors.blue,
      ),
      (
        'Rôle applicatif',
        user.role.label,
        Icons.security_outlined,
        AppColors.gold,
      ),
    ];
    return LayoutBuilder(
      builder: (_, constraints) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: constraints.maxWidth >= 650 ? 3 : 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: constraints.maxWidth < 350 ? 1.45 : 1.7,
        ),
        itemBuilder: (_, index) {
          final item = items[index];
          return Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [item.$4.withValues(alpha: .12), AppColors.surface],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x100B281E),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.$3, color: item.$4, size: 17),
                const Spacer(),
                Text(
                  item.$1,
                  style: const TextStyle(
                    color: AppColors.textSoft,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.$2,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900),
  );

  Widget _setting(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: color.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Row(
            children: [
              EsgeIconBadge(icon: icon, color: color, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSoft,
                        fontSize: 8.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color, size: 18),
            ],
          ),
        ),
      ),
    ),
  );

  void _openOption(
    BuildContext context,
    String title,
    IconData icon,
    List<String> options,
    Color color,
    ProfileOptionKind kind,
  ) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ProfileOptionPage(
        title: title,
        icon: icon,
        options: options,
        color: color,
        kind: kind,
      ),
    ),
  );
}
