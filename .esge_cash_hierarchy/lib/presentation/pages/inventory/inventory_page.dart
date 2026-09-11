import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/inventory/inventory_cubit.dart';
import '../../../business_logic/inventory/inventory_state.dart';
import '../../../business_logic/auth/auth_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/feature_scaffold.dart';
import '../../widgets/analytics_widgets.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});
  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<InventoryCubit>().load();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<InventoryCubit, InventoryState>(
        builder: (context, _) => FeatureScaffold(
          title: 'Stock & logistique',
          subtitle: 'Articles, entrées, sorties, inventaire et alertes',
          icon: Icons.inventory_2,
          color: AppColors.info,
          actions: const [
            'Catalogue',
            'Entrées',
            'Sorties',
            'Inventaire',
            'Sous seuil',
            'Ruptures',
            'Mouvements',
          ],
          primaryAction:
              context.read<AuthCubit>().state.user?.role == UserRole.magasinier
              ? 'Créer un article'
              : null,
          leadingChildren: [
            const KpiStrip(
              items: [
                ('Valeur', '18,4 M', Icons.savings, AppColors.cyan),
                ('Sous seuil', '3', Icons.warning, AppColors.gold),
                ('Ruptures', '1', Icons.remove_shopping_cart, AppColors.coral),
              ],
            ),
          ],
          children: const [],
        ),
      );
}
