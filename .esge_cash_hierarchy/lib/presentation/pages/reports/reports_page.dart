import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/analytics_widgets.dart';
import '../../widgets/esge_ui.dart';
import '../../widgets/feature_scaffold.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
      leadingChildren: [
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
      ],
      children: const [],
    );
  }
}
