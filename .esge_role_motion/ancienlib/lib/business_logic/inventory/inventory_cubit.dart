import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/esge_repository.dart';
import 'inventory_state.dart';

class InventoryCubit extends Cubit<InventoryState> {
  InventoryCubit(this.repository) : super(const InventoryState());
  final EsgeRepository repository;
  Future<void> load() async {
    emit(state.copyWith(status: InventoryStatus.loading));
    emit(
      state.copyWith(
        status: InventoryStatus.loaded,
        items: await repository.inventory(),
      ),
    );
  }
}
