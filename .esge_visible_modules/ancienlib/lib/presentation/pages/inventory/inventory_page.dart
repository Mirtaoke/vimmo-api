import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/inventory/inventory_cubit.dart';
import '../../../business_logic/inventory/inventory_state.dart';
import '../../../core/theme/app_colors.dart';
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
        builder: (_, state) => FeatureScaffold(
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
          primaryAction: 'Créer un article',
          children: [
            const KpiStrip(
              items: [
                ('Valeur', '18,4 M', Icons.savings, AppColors.cyan),
                ('Sous seuil', '3', Icons.warning, AppColors.gold),
                ('Ruptures', '1', Icons.remove_shopping_cart, AppColors.coral),
              ],
            ),
            const SizedBox(height: 18),
            ...state.items.map(
              (item) => ProgressTile(
                title: item.name,
                meta: '${item.code} • ${item.location} • ${item.category}',
                value: '${item.quantity} ${item.unit}',
                progress: (item.quantity / (item.minimumStock * 3)).clamp(0, 1),
                icon: Icons.inventory_2,
                color: item.isLowStock ? AppColors.danger : AppColors.info,
              ),
            ),
          ],
        ),
      );
}
