import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/analytics_widgets.dart';
import '../../widgets/esge_ui.dart';
import '../../widgets/feature_scaffold.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const reports = <(String, String, IconData, Color)>[
      (
        'Journal de caisse',
        'Actualisé aujourd’hui • 248 lignes',
        Icons.account_balance_wallet_outlined,
        AppColors.cyan,
      ),
      (
        'Situation dettes & créances',
        'Échéance la plus proche dans 2 jours',
        Icons.swap_horiz_rounded,
        AppColors.violet,
      ),
      (
        'État et mouvements du stock',
        '8 alertes sur 326 références',
        Icons.inventory_2_outlined,
        AppColors.orange,
      ),
      (
        'Pipeline commercial',
        '72 opportunités • 6 conversions',
        Icons.trending_up_rounded,
        AppColors.green,
      ),
      (
        'Rapport de présence',
        '96% de présence cette semaine',
        Icons.groups_outlined,
        AppColors.blue,
      ),
      (
        'Journal d’audit',
        '1 420 opérations sécurisées',
        Icons.shield_outlined,
        AppColors.violet2,
      ),
    ];
    return FeatureScaffold(
      title: 'Rapports & audit',
      subtitle: 'Analyse consolidée, exports et traçabilité',
      icon: Icons.analytics_outlined,
      color: AppColors.cyan,
      actions: const [
        'Vue globale',
        'Caisse',
        'Prestataires',
        'Stocks',
        'Prospection',
        'Présence',
        'Audit',
      ],
      children: [
        EsgeGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'REVENU / ACTIVITÉ',
                        style: TextStyle(
                          color: AppColors.textSoft,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .7,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        '125 430 500 F',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  EsgeStatusChip('+12,5 %', color: AppColors.green),
                ],
              ),
              const SizedBox(height: 16),
              const SparklineBars(
                values: [26, 47, 35, 60, 52, 69, 78],
                height: 80,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...reports.map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                EsgeIconBadge(icon: item.$3, color: item.$4, size: 42),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$1,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${item.$2} • PDF • Excel • CSV',
                        maxLines: 2,
                        style: const TextStyle(
                          color: AppColors.textSoft,
                          fontSize: 8.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Export de ${item.$1} préparé')),
                  ),
                  icon: const Icon(
                    Icons.download_rounded,
                    color: AppColors.cyan,
                    size: 19,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
