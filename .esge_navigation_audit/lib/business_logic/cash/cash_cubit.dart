import 'package:flutter_bloc/flutter_bloc.dart';
import 'cash_state.dart';

class CashCubit extends Cubit<CashState> {
  CashCubit() : super(const CashState());
  void recordIncome(double amount) =>
      emit(state.copyWith(balance: state.balance + amount));
  void recordExpense(double amount) =>
      emit(state.copyWith(balance: state.balance - amount));
}
