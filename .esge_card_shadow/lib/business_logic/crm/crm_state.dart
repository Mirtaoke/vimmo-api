import '../../data/models/prospect_model.dart';

enum CrmStatus { initial, loading, loaded, failure }

class CrmState {
  const CrmState({this.status = CrmStatus.initial, this.prospects = const []});
  final CrmStatus status;
  final List<ProspectModel> prospects;
  CrmState copyWith({CrmStatus? status, List<ProspectModel>? prospects}) =>
      CrmState(
        status: status ?? this.status,
        prospects: prospects ?? this.prospects,
      );
}
