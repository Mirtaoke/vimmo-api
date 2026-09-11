import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/cash/cash_cubit.dart';
import '../../../business_logic/cash/cash_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/feature_scaffold.dart';
import '../../widgets/analytics_widgets.dart';

class CashPage extends StatelessWidget {
  const CashPage({super.key, this.canCreateCashVoucher = false});

  final bool canCreateCashVoucher;
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
      showHero: false,
      primaryAction: canCreateCashVoucher ? 'Nouveau bon de caisse' : null,
      leadingChildren: [
        BalanceVisual(value: '${state.balance.toStringAsFixed(0)} F CFA'),
        const SizedBox(height: 14),
        const KpiStrip(
          items: [
            ('Entrées', '5,0 M', Icons.south_west, AppColors.lime),
            ('Sorties', '1,9 M', Icons.north_east, AppColors.coral),
            ('À exécuter', '5', Icons.payments, AppColors.violet),
          ],
        ),
      ],
      children: const [],
    ),
  );
}
