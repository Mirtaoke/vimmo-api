import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/esge_ui.dart';
import '../../widgets/feature_scaffold.dart';

class DocumentsPage extends StatelessWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const docs = [
      (
        'FACT-2026-084.pdf',
        'Facture prestataire • 1,8 Mo',
        Icons.picture_as_pdf_outlined,
        AppColors.red,
      ),
      (
        'BON-CAISSE-0248.pdf',
        'Bon de caisse • 640 Ko',
        Icons.receipt_long_outlined,
        AppColors.cyan,
      ),
      (
        'PROPOSITION-NOVA.pdf',
        'Proposition commerciale • 2,1 Mo',
        Icons.description_outlined,
        AppColors.violet,
      ),
      (
        'INVENTAIRE-AOUT.xlsx',
        'Inventaire stock • 860 Ko',
        Icons.table_chart_outlined,
        AppColors.green,
      ),
    ];
    return FeatureScaffold(
      title: 'Documents',
      subtitle: 'Justificatifs, factures, bons, contrats et rapports',
      icon: Icons.folder_copy_outlined,
      color: AppColors.blue,
      actions: const [
        'Tous',
        'Factures',
        'Bons',
        'Contrats',
        'Propositions',
        'Rapports',
      ],
      primaryAction: 'Ajouter un document',
      children: [
        EsgeGlassCard(
          gradient: LinearGradient(
            colors: [
              AppColors.cyan.withValues(alpha: .08),
              AppColors.violet.withValues(alpha: .08),
            ],
          ),
          child: const Row(
            children: [
              EsgeIconBadge(
                icon: Icons.lock_outline_rounded,
                color: AppColors.cyan,
              ),
              SizedBox(width: 11),
              Expanded(
                child: Text(
                  'Les documents restent rattachés à leur entité et accessibles uniquement aux profils autorisés.',
                  style: TextStyle(
                    color: AppColors.textSoft,
                    fontSize: 9.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...docs.map(
          (d) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                EsgeIconBadge(icon: d.$3, color: d.$4, size: 41),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.$1,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        d.$2,
                        style: const TextStyle(
                          color: AppColors.textSoft,
                          fontSize: 8.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.more_horiz_rounded,
                  color: AppColors.textSoft,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
