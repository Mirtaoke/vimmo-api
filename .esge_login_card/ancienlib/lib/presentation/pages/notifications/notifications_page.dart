import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/brand_mark.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
      children: [
        const Row(
          children: [
            BrandMark(),
            Spacer(),
            CircleAvatar(
              backgroundColor: AppColors.lavender,
              child: Icon(Icons.done_all, color: AppColors.appPurple),
            ),
          ],
        ),
        const SizedBox(height: 26),
        const Text(
          'Centre d’alertes',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        const Text(
          'Validations, stocks, rendez-vous et pointage',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppColors.appPurpleDark,
                AppColors.appPurple,
                AppColors.peach,
              ],
            ),
            borderRadius: BorderRadius.circular(26),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: Colors.white24,
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '5 actions vous attendent',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      '2 urgentes • 3 informations',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ...List.generate(
          7,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.line),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              leading: CircleAvatar(
                backgroundColor:
                    (i.isEven ? AppColors.coral : AppColors.primary).withValues(
                      alpha: .12,
                    ),
                child: Icon(
                  i.isEven ? Icons.warning_amber : Icons.verified_user,
                  color: i.isEven ? AppColors.coral : AppColors.primary,
                ),
              ),
              title: Text(
                i.isEven
                    ? 'Stock faible — Papier A4'
                    : 'Demande à valider — DEC-0248',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text('Il y a ${i + 1} heure(s)'),
              trailing: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i < 3 ? AppColors.coral : AppColors.line,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
