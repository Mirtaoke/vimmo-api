import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/role_extensions.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/esge_ui.dart';
import '../../widgets/feature_scaffold.dart';

class UsersPermissionsPage extends StatelessWidget {
  const UsersPermissionsPage({super.key});

  @override
  Widget build(BuildContext context) => FeatureScaffold(
    title: 'Utilisateurs & permissions',
    subtitle: 'Comptes, rôles, statuts, sessions et droits granulaires',
    icon: Icons.admin_panel_settings_outlined,
    color: AppColors.violet,
    actions: const [
      'Utilisateurs',
      'Rôles',
      'Permissions',
      'Sessions',
      'Connexions',
    ],
    primaryAction: 'Créer un utilisateur',
    leadingChildren: [
      Row(
        children: [
          Expanded(child: _stat('42', 'Utilisateurs actifs', AppColors.cyan)),
          const SizedBox(width: 8),
          Expanded(child: _stat('7', 'Rôles', AppColors.violet)),
          const SizedBox(width: 8),
          Expanded(child: _stat('3', 'Sessions à vérifier', AppColors.orange)),
        ],
      ),
    ],
    children: [
      const Text(
        'RÔLES & ACCÈS',
        style: TextStyle(
          color: AppColors.textSoft,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: .8,
        ),
      ),
      const SizedBox(height: 9),
      ...UserRole.values.map(
        (role) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              EsgeIconBadge(icon: role.icon, color: AppColors.violet, size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.label,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Permissions configurables • accès limité au périmètre autorisé',
                      style: TextStyle(
                        color: AppColors.textSoft,
                        fontSize: 8.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSoft,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _stat(String value, String label, Color color) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [color.withValues(alpha: .12), AppColors.surface],
      ),
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: color.withValues(alpha: .18)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 2,
          style: const TextStyle(
            color: AppColors.textSoft,
            fontSize: 8,
            height: 1.2,
          ),
        ),
      ],
    ),
  );
}
