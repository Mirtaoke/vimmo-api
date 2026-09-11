import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/user_model.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState());
  void signInAs(UserRole role) {
    emit(
      AuthState(
        status: AuthStatus.authenticated,
        user: UserModel(
          id: 'demo',
          fullName: 'Aïcha DOSSOU',
          email: 'aicha@esge.bj',
          phone: '+229 01 97 00 00 00',
          jobTitle: _jobTitle(role),
          service: _service(role),
          identifier: 'ESGE-0024',
          entryDate: '15 janvier 2024',
          managerName: _manager(role),
          role: role,
          permissions: _permissions(role),
        ),
      ),
    );
  }

  void signOut() => emit(const AuthState());

  void updateProfile({
    required String fullName,
    required String email,
    required String phone,
    String? photoUrl,
    bool removePhoto = false,
  }) {
    final currentUser = state.user;
    if (currentUser == null) return;
    emit(
      state.copyWith(
        user: UserModel(
          id: currentUser.id,
          fullName: fullName,
          email: email,
          phone: phone,
          jobTitle: currentUser.jobTitle,
          service: currentUser.service,
          identifier: currentUser.identifier,
          entryDate: currentUser.entryDate,
          managerName: currentUser.managerName,
          role: currentUser.role,
          permissions: currentUser.permissions,
          photoUrl: removePhoto ? null : photoUrl ?? currentUser.photoUrl,
          isActive: currentUser.isActive,
        ),
        message: 'Profil mis à jour',
      ),
    );
  }
}

String _jobTitle(UserRole role) => switch (role) {
  UserRole.admin => 'Administrateur système',
  UserRole.dg => 'Directrice générale',
  UserRole.comptable => 'Comptable',
  UserRole.secretaire => 'Secrétaire administrative',
  UserRole.caissier => 'Caissier',
  UserRole.magasinier => 'Magasinier / Logisticien',
  UserRole.commercial => 'Chargé commercial',
};

String _service(UserRole role) => switch (role) {
  UserRole.admin => 'Systèmes d’information',
  UserRole.dg => 'Direction générale',
  UserRole.comptable => 'Finance & comptabilité',
  UserRole.secretaire => 'Administration',
  UserRole.caissier => 'Caisse',
  UserRole.magasinier => 'Logistique & stock',
  UserRole.commercial => 'Commercial',
};

String _manager(UserRole role) => switch (role) {
  UserRole.dg => 'Conseil d’administration',
  UserRole.admin => 'Direction générale',
  _ => 'Aïcha DOSSOU — Direction générale',
};

List<String> _permissions(UserRole role) => switch (role) {
  UserRole.dg => ['Pilotage global', 'Validation DG', 'Rapports & exports'],
  UserRole.comptable => [
    'Contrôle comptable',
    'Validation comptable',
    'Rapports',
  ],
  UserRole.secretaire => ['Créer une demande', 'Gérer les dossiers', 'Agenda'],
  UserRole.caissier => [
    'Exécuter un bon',
    'Gérer la caisse',
    'Consulter les soldes',
  ],
  UserRole.magasinier => ['Gérer le stock', 'Mouvements', 'Inventaires'],
  UserRole.commercial => ['Gérer les prospects', 'Clients', 'Rendez-vous'],
  UserRole.admin => ['Utilisateurs', 'Rôles', 'Permissions'],
};
