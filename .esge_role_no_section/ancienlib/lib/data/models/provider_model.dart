class ProviderModel {
  const ProviderModel({
    required this.id,
    required this.companyName,
    required this.type,
    required this.contactName,
    required this.phone,
    required this.receivable,
    required this.payable,
    this.isActive = true,
  });
  final String id, companyName, type, contactName, phone;
  final double receivable, payable;
  final bool isActive;
  double get netBalance => receivable - payable;
}
