import '../../data/models/provider_model.dart';

enum ProviderStatus { initial, loading, loaded, failure }

class ProviderState {
  const ProviderState({
    this.status = ProviderStatus.initial,
    this.items = const [],
  });
  final ProviderStatus status;
  final List<ProviderModel> items;
  ProviderState copyWith({
    ProviderStatus? status,
    List<ProviderModel>? items,
  }) =>
      ProviderState(status: status ?? this.status, items: items ?? this.items);
}
