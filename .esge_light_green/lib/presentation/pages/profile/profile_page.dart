import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/auth/auth_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/role_extensions.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/esge_ui.dart';
import '../auth/role_selection_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().state.user!;
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
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user.role.label,
                            style: const TextStyle(
                              color: AppColors.textSoft,
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
                      color: AppColors.cyan,
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
              ].map((e) => _setting(e.$1, e.$2)),
              const SizedBox(height: 14),
              const Text(
                'Préférences',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 9),
              _setting('Notifications', Icons.notifications_none_rounded),
              _setting('Langue', Icons.language_rounded, trailing: 'Français'),
              _setting('Sécurité documentaire', Icons.folder_special_outlined),
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

  Widget _setting(String label, IconData icon, {String? trailing}) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: AppColors.line),
    ),
    child: ListTile(
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
  );
}
