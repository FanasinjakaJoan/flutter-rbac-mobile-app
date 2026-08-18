import 'package:equatable/equatable.dart';
import 'package:rbac_mobile_app/core/security/app_permission.dart';
import 'package:rbac_mobile_app/core/security/permission_matrix.dart';
import 'package:rbac_mobile_app/features/auth/domain/entities/app_user.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.permissions = PermissionMatrix.defaults,
  });

  const AuthState.initial()
      : status = AuthStatus.initial,
        user = null,
        errorMessage = null,
        permissions = PermissionMatrix.defaults;

  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage;

  /// Matrice RBAC active pour cette session, diffusée par le `RbacService`.
  final PermissionMatrix permissions;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;

  /// Évalue une permission pour l'utilisateur connecté.
  bool can(AppPermission permission) {
    final current = user;
    if (current == null) {
      return false;
    }
    return permissions.can(current.role, permission);
  }

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    bool clearUser = false,
    String? errorMessage,
    bool clearError = false,
    PermissionMatrix? permissions,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: clearUser ? null : (user ?? this.user),
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        permissions: permissions ?? this.permissions,
      );

  @override
  List<Object?> get props => [status, user, errorMessage, permissions];
}
