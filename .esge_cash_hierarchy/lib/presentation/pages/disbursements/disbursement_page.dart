import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/disbursements/disbursement_cubit.dart';
import '../../../business_logic/disbursements/disbursement_state.dart';
import '../../../business_logic/auth/auth_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/feature_scaffold.dart';
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
  Widget build(BuildContext context) =>
      BlocBuilder<DisbursementCubit, DisbursementState>(
        builder: (_, _) => FeatureScaffold(
          title: 'Demandes & validations',
          subtitle: 'Secrétaire → Comptable → DG → Caissier',
          icon: Icons.verified_user,
          color: AppColors.primary,
          actions: _actionsFor(
            context.read<AuthCubit>().state.user?.role ?? UserRole.secretaire,
          ),
          primaryAction:
              context.read<AuthCubit>().state.user?.role == UserRole.secretaire
              ? 'Créer une demande'
              : null,
          leadingChildren: [
            const KpiStrip(
              items: [
                ('Demandes', '12', Icons.fact_check, AppColors.orange),
                ('Approuvées', '6', Icons.verified, AppColors.indigo),
                ('Refusées', '4', Icons.cancel_outlined, AppColors.coral),
              ],
            ),
          ],
          children: const [],
        ),
      );

  List<String> _actionsFor(UserRole role) => switch (role) {
    UserRole.dg => const [
      'Demandes',
      'Approuvées',
      'Refusées',
      'Exécutées',
      'Historique',
    ],
    UserRole.comptable => const [
      'Demandes',
      'Approuvées',
      'Refusées',
      'Historique',
    ],
    UserRole.caissier => const [
      'Demandes exécutables',
      'Exécutées',
      'Historique',
    ],
    _ => const [
      'Demandes',
      'Approuvées',
      'Refusées',
      'Exécutées',
      'Historique',
    ],
  };
}
