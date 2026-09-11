import '../local/sample_data.dart';
import '../models/disbursement_model.dart';
import '../models/inventory_item_model.dart';
import '../models/prospect_model.dart';
import '../models/provider_model.dart';

class EsgeRepository {
  Future<List<DisbursementModel>> disbursements() async =>
      SampleData.disbursements;
  Future<List<ProviderModel>> providers() async => SampleData.providers;
  Future<List<InventoryItemModel>> inventory() async => SampleData.inventory;
  Future<List<ProspectModel>> prospects() async => SampleData.prospects;
}
