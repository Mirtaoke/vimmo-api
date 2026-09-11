class AuditLogModel {
  const AuditLogModel({
    required this.id,
    required this.userName,
    required this.action,
    required this.entity,
    required this.reference,
    required this.createdAt,
    this.oldValue,
    this.newValue,
  });
  final String id, userName, action, entity, reference;
  final DateTime createdAt;
  final String? oldValue, newValue;
}
