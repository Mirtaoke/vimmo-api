import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/crm/crm_cubit.dart';
import '../../../business_logic/crm/crm_state.dart';
import '../../../business_logic/auth/auth_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/feature_scaffold.dart';
import '../../widgets/analytics_widgets.dart';

class CrmPage extends StatefulWidget {
  const CrmPage({super.key});
  @override
  State<CrmPage> createState() => _CrmPageState();
}

class _CrmPageState extends State<CrmPage> {
  static const color = AppColors.cocoa;
  @override
  void initState() {
    super.initState();
    context.read<CrmCubit>().load();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<CrmCubit, CrmState>(
    builder: (context, _) => FeatureScaffold(
      title: 'CRM commercial',
      subtitle: 'Du suspect à la conversion en client',
      icon: Icons.hub,
      color: color,
      actions: const [
        'Pipeline',
        'Suspects',
        'Prospects',
        'Rendez-vous',
        'Propositions',
        'Clients',
        'Rapports',
      ],
      primaryAction:
          context.read<AuthCubit>().state.user?.role == UserRole.commercial
          ? 'Ajouter un prospect'
          : null,
      leadingChildren: [
        const PipelineBar(),
        const SizedBox(height: 18),
        const KpiStrip(
          items: [
            ('Rendez-vous', '7', Icons.calendar_month, AppColors.cyan),
            ('Propositions', '14', Icons.description, AppColors.violet),
            ('Conversions', '6', Icons.handshake, AppColors.lime),
          ],
        ),
      ],
      children: const [],
    ),
  );
}
