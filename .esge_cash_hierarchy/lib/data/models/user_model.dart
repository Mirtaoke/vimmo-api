enum UserRole {
  admin,
  dg,
  comptable,
  secretaire,
  caissier,
  magasinier,
  commercial,
}

class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.jobTitle,
    required this.service,
    required this.identifier,
    required this.entryDate,
    required this.managerName,
    required this.role,
    required this.permissions,
    this.photoUrl,
    this.isActive = true,
  });
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String jobTitle;
  final String service;
  final String identifier;
  final String entryDate;
  final String managerName;
  final UserRole role;
  final List<String> permissions;
  final String? photoUrl;
  final bool isActive;
}
