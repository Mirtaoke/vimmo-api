import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/esge_repository.dart';
import 'provider_state.dart';

class ProviderCubit extends Cubit<ProviderState> {
  ProviderCubit(this.repository) : super(const ProviderState());
  final EsgeRepository repository;
  Future<void> load() async {
    emit(state.copyWith(status: ProviderStatus.loading));
    emit(
      state.copyWith(
        status: ProviderStatus.loaded,
        items: await repository.providers(),
      ),
    );
  }
}
