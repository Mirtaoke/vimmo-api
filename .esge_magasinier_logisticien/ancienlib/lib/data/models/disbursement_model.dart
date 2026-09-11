enum DisbursementStatus {
  draft,
  accountantPending,
  dgPending,
  approved,
  rejected,
  returned,
  executed,
}

class DisbursementModel {
  const DisbursementModel({
    required this.id,
    required this.reference,
    required this.requester,
    required this.beneficiary,
    required this.label,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.provider,
  });
  final String id, reference, requester, beneficiary, label;
  final double amount;
  final DisbursementStatus status;
  final DateTime createdAt;
  final String? provider;
}
