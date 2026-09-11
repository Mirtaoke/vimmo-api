class InventoryItemModel {
  const InventoryItemModel({
    required this.code,
    required this.name,
    required this.category,
    required this.unit,
    required this.location,
    required this.quantity,
    required this.minimumStock,
    required this.unitPrice,
  });
  final String code, name, category, unit, location;
  final double quantity, minimumStock, unitPrice;
  bool get isLowStock => quantity <= minimumStock;
  double get stockValue => quantity * unitPrice;
}
