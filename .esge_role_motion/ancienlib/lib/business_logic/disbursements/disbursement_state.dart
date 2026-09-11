import '../../data/models/disbursement_model.dart';

enum DisbursementLoadStatus { initial, loading, loaded, failure }

class DisbursementState {
  const DisbursementState({
    this.status = DisbursementLoadStatus.initial,
    this.items = const [],
    this.message,
  });
  final DisbursementLoadStatus status;
  final List<DisbursementModel> items;
  final String? message;
  DisbursementState copyWith({
    DisbursementLoadStatus? status,
    List<DisbursementModel>? items,
    String? message,
  }) => DisbursementState(
    status: status ?? this.status,
    items: items ?? this.items,
    message: message,
  );
}
