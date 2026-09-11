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
          role: role,
          department: role.name,
        ),
      ),
    );
  }

  void signOut() => emit(const AuthState());

  void updateProfile({
    required String fullName,
    required String email,
    required String department,
  }) {
    final currentUser = state.user;
    if (currentUser == null) return;
    emit(
      state.copyWith(
        user: UserModel(
          id: currentUser.id,
          fullName: fullName,
          email: email,
          role: currentUser.role,
          department: department,
          photoUrl: currentUser.photoUrl,
          isActive: currentUser.isActive,
        ),
        message: 'Profil mis à jour',
      ),
    );
  }
}
