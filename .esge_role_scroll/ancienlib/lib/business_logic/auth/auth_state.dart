import '../../data/models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, failure }

class AuthState {
  const AuthState({this.status = AuthStatus.initial, this.user, this.message});
  final AuthStatus status;
  final UserModel? user;
  final String? message;
  AuthState copyWith({AuthStatus? status, UserModel? user, String? message}) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        message: message,
      );
}
