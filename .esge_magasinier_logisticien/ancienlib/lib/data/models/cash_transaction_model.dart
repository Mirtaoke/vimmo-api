enum CashTransactionType { income, expense, adjustment }

class CashTransactionModel {
  const CashTransactionModel({
    required this.id,
    required this.reference,
    required this.beneficiary,
    required this.label,
    required this.amount,
    required this.type,
    required this.date,
  });
  final String id, reference, beneficiary, label;
  final double amount;
  final CashTransactionType type;
  final DateTime date;
}
