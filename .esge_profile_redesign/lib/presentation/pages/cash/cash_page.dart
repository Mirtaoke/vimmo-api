import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/cash/cash_cubit.dart';
import '../../../business_logic/cash/cash_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/feature_scaffold.dart';
import '../../widgets/analytics_widgets.dart';
import '../../widgets/record_card.dart';

class CashPage extends StatelessWidget {
  const CashPage({super.key});
  @override
  Widget build(BuildContext context) => BlocBuilder<CashCubit, CashState>(
    builder: (_, state) => FeatureScaffold(
      title: 'Caisse',
      subtitle: 'Solde automatique, entrées, sorties et bons',
      icon: Icons.account_balance_wallet,
      color: AppColors.gold,
      actions: const [
        'Entrées',
        'Sorties',
        'Bons de caisse',
        'Demandes exécutables',
        'Recherche avancée',
      ],
      primaryAction: 'Nouveau bon de caisse',
      children: [
        BalanceVisual(value: '${state.balance.toStringAsFixed(0)} F CFA'),
        const SizedBox(height: 14),
        const KpiStrip(
          items: [
            ('Entrées', '5,0 M', Icons.south_west, AppColors.lime),
            ('Sorties', '1,9 M', Icons.north_east, AppColors.coral),
            ('À exécuter', '5', Icons.payments, AppColors.violet),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'MOUVEMENTS RÉCENTS',
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        const RecordCard(
          title: 'Mission terrain — Akassato',
          subtitle: 'Bon DEC-0248 • Karim Bio',
          value: '485 000 F',
          color: AppColors.gold,
          status: 'Exécuté',
        ),
        const RecordCard(
          title: 'Approvisionnement caisse',
          subtitle: 'ENT-0089 • Virement',
          value: '+ 5 000 000 F',
          color: AppColors.success,
          status: 'Rapproché',
        ),
      ],
    ),
  );
}
