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
    'Magasinier / Logisticien',
    'Commercial',
  ][index];
  IconData get icon => const [
    Icons.admin_panel_settings,
    Icons.insights,
    Icons.account_balance,
    Icons.edit_note,
    Icons.point_of_sale,
    Icons.inventory_2,
    Icons.handshake,
  ][index];
  Color get color => const [
    AppColors.primary,
    AppColors.charcoal,
    Color(0xFF343434),
    Color(0xFF454545),
    Color(0xFF565656),
    Color(0xFF676767),
    Color(0xFF242424),
  ][index];
}
