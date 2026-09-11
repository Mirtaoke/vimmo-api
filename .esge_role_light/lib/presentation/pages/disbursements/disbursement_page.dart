import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/disbursements/disbursement_cubit.dart';
import '../../../business_logic/disbursements/disbursement_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/feature_scaffold.dart';
import '../../widgets/record_card.dart';
import '../../widgets/analytics_widgets.dart';

class DisbursementPage extends StatefulWidget {
  const DisbursementPage({super.key});
  @override
  State<DisbursementPage> createState() => _DisbursementPageState();
}

class _DisbursementPageState extends State<DisbursementPage> {
  @override
  void initState() {
    super.initState();
    context.read<DisbursementCubit>().load();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<DisbursementCubit, DisbursementState>(
    builder: (_, state) => FeatureScaffold(
      title: 'Demandes & validations',
      subtitle: 'Secrétaire → Comptable → DG → Caissier',
      icon: Icons.verified_user,
      color: AppColors.primary,
      actions: const [
        'À contrôler',
        'Validation DG',
        'Retournées',
        'Exécutées',
        'Historique',
      ],
      primaryAction: 'Créer une demande',
      children: [
        const KpiStrip(
          items: [
            ('À contrôler', '12', Icons.fact_check, AppColors.cyan),
            ('Validation DG', '6', Icons.verified, AppColors.violet),
            ('Exécutées', '28', Icons.check_circle, AppColors.lime),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.navyLight, AppColors.violet],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Text(
            'Une demande ne débite jamais la caisse avant validation DG et exécution effective.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 14),
        ...state.items.map(
          (item) => RecordCard(
            title: item.label,
            subtitle: '${item.reference} • ${item.beneficiary}',
            value: '${item.amount.toStringAsFixed(0)} F',
            color: AppColors.primary,
            status: item.status.name,
          ),
        ),
      ],
    ),
  );
}
