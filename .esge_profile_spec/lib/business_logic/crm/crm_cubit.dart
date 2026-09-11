import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/esge_repository.dart';
import 'crm_state.dart';

class CrmCubit extends Cubit<CrmState> {
  CrmCubit(this.repository) : super(const CrmState());
  final EsgeRepository repository;
  Future<void> load() async {
    emit(state.copyWith(status: CrmStatus.loading));
    emit(
      state.copyWith(
        status: CrmStatus.loaded,
        prospects: await repository.prospects(),
      ),
    );
  }
}
