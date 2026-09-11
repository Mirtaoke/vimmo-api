import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/esge_repository.dart';
import 'disbursement_state.dart';

class DisbursementCubit extends Cubit<DisbursementState> {
  DisbursementCubit(this.repository) : super(const DisbursementState());
  final EsgeRepository repository;
  Future<void> load() async {
    emit(state.copyWith(status: DisbursementLoadStatus.loading));
    emit(
      state.copyWith(
        status: DisbursementLoadStatus.loaded,
        items: await repository.disbursements(),
      ),
    );
  }
}
