import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/auth/auth_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/role_extensions.dart';
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
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.heroGradient,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.cyan.withValues(alpha: .16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppColors.violetGradient,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        user.role.icon,
                        color: Colors.white,
                        size: 27,
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
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user.role.label,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 7),
                          const EsgeStatusChip(
                            'Compte vérifié',
                            color: AppColors.green,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Compte',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 9),
              ...[
                ('Informations personnelles', Icons.person_outline_rounded),
                ('Changer le mot de passe', Icons.lock_outline_rounded),
                ('Authentification à deux facteurs', Icons.shield_outlined),
                ('Appareils & sessions', Icons.devices_outlined),
                ('Permissions', Icons.admin_panel_settings_outlined),
              ].map(
                (e) => _setting(
                  context,
                  e.$1,
                  e.$2,
                  onTap: () => _openAccountPage(context, e.$1, e.$2),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Préférences',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 9),
              _setting(
                context,
                'Notifications',
                Icons.notifications_none_rounded,
                onTap: () => _openOptionPage(
                  context,
                  'Notifications',
                  Icons.notifications_none_rounded,
                  const [
                    'Alertes métier',
                    'Validations',
                    'Rapports hebdomadaires',
                  ],
                ),
              ),
              _setting(
                context,
                'Langue',
                Icons.language_rounded,
                trailing: 'Français',
                onTap: () => _openOptionPage(
                  context,
                  'Langue',
                  Icons.language_rounded,
                  const ['Français', 'Anglais'],
                ),
              ),
              _setting(
                context,
                'Sécurité documentaire',
                Icons.folder_special_outlined,
                onTap: () => _openOptionPage(
                  context,
                  'Sécurité documentaire',
                  Icons.folder_special_outlined,
                  const [
                    'Accès biométrique',
                    'Journal des téléchargements',
                    'Filigrane',
                  ],
                ),
              ),
              const SizedBox(height: 16),
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

  Widget _setting(
    BuildContext context,
    String label,
    IconData icon, {
    String? trailing,
    VoidCallback? onTap,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: EsgeIconBadge(icon: icon, color: AppColors.cyan, size: 36),
        title: Text(
          label,
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800),
        ),
        trailing: trailing == null
            ? const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSoft,
                size: 18,
              )
            : Text(
                trailing,
                style: const TextStyle(color: AppColors.textSoft, fontSize: 9),
              ),
      ),
    ),
  );

  void _openAccountPage(BuildContext context, String label, IconData icon) {
    final page = switch (label) {
      'Informations personnelles' => const PersonalInformationPage(),
      'Changer le mot de passe' => const ChangePasswordPage(),
      'Authentification à deux facteurs' => const ProfileOptionPage(
        title: 'Authentification à deux facteurs',
        icon: Icons.shield_outlined,
        options: [
          'Application d’authentification',
          'Codes de secours',
          'Validation par e-mail',
        ],
      ),
      'Appareils & sessions' => const ProfileOptionPage(
        title: 'Appareils & sessions',
        icon: Icons.devices_outlined,
        options: ['Téléphone actuel', 'Ordinateur professionnel'],
      ),
      _ => const ProfileOptionPage(
        title: 'Permissions',
        icon: Icons.admin_panel_settings_outlined,
        options: [
          'Accès aux rapports',
          'Export de données',
          'Validation sensible',
        ],
      ),
    };
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _openOptionPage(
    BuildContext context,
    String title,
    IconData icon,
    List<String> options,
  ) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          ProfileOptionPage(title: title, icon: icon, options: options),
    ),
  );
}
