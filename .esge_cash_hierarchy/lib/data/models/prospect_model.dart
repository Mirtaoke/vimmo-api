enum ProspectStatus {
  suspect,
  prospect,
  qualified,
  proposalSent,
  negotiation,
  client,
  lost,
}

class ProspectModel {
  const ProspectModel({
    required this.id,
    required this.companyName,
    required this.contact,
    required this.phone,
    required this.need,
    required this.potential,
    required this.status,
    required this.owner,
  });
  final String id, companyName, contact, phone, need, owner;
  final double potential;
  final ProspectStatus status;
}
