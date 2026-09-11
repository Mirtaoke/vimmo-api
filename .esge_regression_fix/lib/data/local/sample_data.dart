import '../models/disbursement_model.dart';
import '../models/inventory_item_model.dart';
import '../models/prospect_model.dart';
import '../models/provider_model.dart';

abstract final class SampleData {
  static final disbursements = [
    DisbursementModel(
      id: '1',
      reference: 'DEC-0248',
      requester: 'Aïcha Dossou',
      beneficiary: 'Karim Bio',
      label: 'Mission terrain Akassato',
      amount: 485000,
      status: DisbursementStatus.dgPending,
      createdAt: DateTime.now(),
    ),
    DisbursementModel(
      id: '2',
      reference: 'DEC-0247',
      requester: 'Mireille Houngbo',
      beneficiary: 'Global Tech SARL',
      label: 'Maintenance informatique',
      amount: 1250000,
      status: DisbursementStatus.approved,
      createdAt: DateTime.now(),
    ),
  ];
  static const providers = [
    ProviderModel(
      id: '1',
      companyName: 'Global Tech SARL',
      type: 'Technicien',
      contactName: 'Rodrigue A.',
      phone: '+229 01 97 00 00 00',
      receivable: 350000,
      payable: 1250000,
    ),
    ProviderModel(
      id: '2',
      companyName: 'Office Plus',
      type: 'Fournisseur',
      contactName: 'Aline K.',
      phone: '+229 01 96 00 00 00',
      receivable: 0,
      payable: 675000,
    ),
  ];
  static const inventory = [
    InventoryItemModel(
      code: 'ART-001',
      name: 'Papier A4',
      category: 'Fournitures',
      unit: 'Ramette',
      location: 'A-12',
      quantity: 8,
      minimumStock: 10,
      unitPrice: 3500,
    ),
    InventoryItemModel(
      code: 'ART-002',
      name: 'Cartouche HP 59A',
      category: 'Informatique',
      unit: 'Pièce',
      location: 'B-04',
      quantity: 24,
      minimumStock: 5,
      unitPrice: 48000,
    ),
  ];
  static const prospects = [
    ProspectModel(
      id: '1',
      companyName: 'Bénin Agro Industries',
      contact: 'Cédric T.',
      phone: '+229 01 95 00 00 00',
      need: 'Solution de gestion',
      potential: 8500000,
      status: ProspectStatus.negotiation,
      owner: 'Fatou K.',
    ),
    ProspectModel(
      id: '2',
      companyName: 'Nova Services',
      contact: 'Sarah D.',
      phone: '+229 01 94 00 00 00',
      need: 'Audit digital',
      potential: 3200000,
      status: ProspectStatus.qualified,
      owner: 'Fatou K.',
    ),
  ];
}
