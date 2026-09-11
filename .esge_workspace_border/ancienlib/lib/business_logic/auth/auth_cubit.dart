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
}
