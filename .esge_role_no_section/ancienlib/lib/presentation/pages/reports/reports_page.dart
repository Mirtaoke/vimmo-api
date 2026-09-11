import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/feature_scaffold.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});
  @override
  Widget build(BuildContext context) {
    const reports = <(String, String, IconData, Color)>[
      (
        'Journal de caisse',
        'Actualisé aujourd’hui • 248 lignes',
        Icons.account_balance_wallet_rounded,
        AppColors.success,
      ),
      (
        'Situation dettes & créances',
        'Échéance la plus proche dans 2 jours',
        Icons.swap_horiz_rounded,
        AppColors.peach,
      ),
      (
        'État et mouvements du stock',
        '8 alertes sur 326 références',
        Icons.inventory_2_rounded,
        AppColors.violet,
      ),
      (
        'Pipeline commercial',
        '72 opportunités • 6 conversions',
        Icons.trending_up_rounded,
        AppColors.gold,
      ),
      (
        'Rapport de présence',
        '96% de présence cette semaine',
        Icons.groups_rounded,
        AppColors.info,
      ),
      (
        'Journal d’audit',
        '1 420 opérations sécurisées',
        Icons.shield_rounded,
        AppColors.appPurple,
      ),
    ];
    return FeatureScaffold(
      title: 'Rapports, exports & audit',
      subtitle: 'Analyse consolidée et piste de traçabilité',
      icon: Icons.analytics,
      color: AppColors.navy,
      actions: const [
        'Journal caisse',
        'Décaissements',
        'Prestataires',
        'Stocks',
        'Prospection',
        'Présence',
        'Audit',
      ],
      children: reports
          .map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(23),
                border: Border.all(color: AppColors.line),
              ),
              child: ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [item.$4, item.$4.withValues(alpha: .6)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(item.$3, color: Colors.white),
                ),
                title: Text(
                  item.$1,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text('${item.$2}\nPDF • Excel • CSV'),
                isThreeLine: true,
                trailing: IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.download_rounded,
                    color: AppColors.appPurple,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
