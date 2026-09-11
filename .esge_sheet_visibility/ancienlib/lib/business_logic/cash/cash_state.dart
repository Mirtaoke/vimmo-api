import '../../data/models/cash_transaction_model.dart';

class CashState {
  const CashState({this.balance = 24850000, this.transactions = const []});
  final double balance;
  final List<CashTransactionModel> transactions;
  CashState copyWith({
    double? balance,
    List<CashTransactionModel>? transactions,
  }) => CashState(
    balance: balance ?? this.balance,
    transactions: transactions ?? this.transactions,
  );
}
