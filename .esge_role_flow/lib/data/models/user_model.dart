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
    required this.role,
    required this.department,
    this.photoUrl,
    this.isActive = true,
  });
  final String id, fullName, email, department;
  final UserRole role;
  final String? photoUrl;
  final bool isActive;
}
