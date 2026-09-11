import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/feature_scaffold.dart';

class DocumentsPage extends StatelessWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
      children: const [],
    );
  }
}
