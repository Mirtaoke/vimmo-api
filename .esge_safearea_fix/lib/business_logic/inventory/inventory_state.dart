import '../../data/models/inventory_item_model.dart';

enum InventoryStatus { initial, loading, loaded, failure }

class InventoryState {
  const InventoryState({
    this.status = InventoryStatus.initial,
    this.items = const [],
  });
  final InventoryStatus status;
  final List<InventoryItemModel> items;
  InventoryState copyWith({
    InventoryStatus? status,
    List<InventoryItemModel>? items,
  }) =>
      InventoryState(status: status ?? this.status, items: items ?? this.items);
}
