import 'package:equatable/equatable.dart';
import 'package:rbac_mobile_app/features/auth/domain/entities/app_user.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  const AuthState.initial()
      : status = AuthStatus.initial,
        user = null,
        errorMessage = null;

  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;

  @override
  List<Object?> get props => [status, user, errorMessage];
}
