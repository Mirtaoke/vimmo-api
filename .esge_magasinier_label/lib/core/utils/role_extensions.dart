import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../theme/app_colors.dart';

extension UserRolePresentation on UserRole {
  String get label => const [
    'Administrateur',
    'Directeur général',
    'Comptable',
    'Secrétaire',
    'Caissier',
    'Magasinier',
    'Commercial',
  ][index];

  IconData get icon => const [
    Icons.admin_panel_settings_outlined,
    Icons.insights_outlined,
    Icons.account_balance_outlined,
    Icons.edit_note_outlined,
    Icons.point_of_sale_outlined,
    Icons.inventory_2_outlined,
    Icons.handshake_outlined,
  ][index];

  /// The same accent is intentionally used for every role.
  Color get color => AppColors.cyan;
}
