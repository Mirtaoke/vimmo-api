import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/providers/provider_cubit.dart';
import '../../../business_logic/providers/provider_state.dart';
import '../../../business_logic/auth/auth_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/feature_scaffold.dart';
import '../../widgets/analytics_widgets.dart';

class ProvidersPage extends StatefulWidget {
  const ProvidersPage({super.key});
  @override
  State<ProvidersPage> createState() => _ProvidersPageState();
}

class _ProvidersPageState extends State<ProvidersPage> {
  @override
  void initState() {
    super.initState();
    context.read<ProviderCubit>().load();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ProviderCubit, ProviderState>(
        builder: (context, _) => FeatureScaffold(
          title: 'Comptabilité prestataires',
          subtitle: 'Dettes, créances, règlements et solde net',
          icon: Icons.apartment,
          color: AppColors.success,
          actions: const [
            'Base prestataires',
            'Créances',
            'Dettes',
            'Échéances',
            'Règlements',
            'Documents',
          ],
          primaryAction:
              context.read<AuthCubit>().state.user?.role == UserRole.comptable
              ? 'Ajouter un prestataire'
              : null,
          leadingChildren: [
            const KpiStrip(
              items: [
                ('À payer', '9,8 M', Icons.call_made, AppColors.coral),
                ('À recevoir', '3,2 M', Icons.call_received, AppColors.lime),
                ('Échéances', '4', Icons.event, AppColors.violet),
              ],
            ),
          ],
          children: const [],
        ),
      );
}
