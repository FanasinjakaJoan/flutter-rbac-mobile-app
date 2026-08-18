import 'package:equatable/equatable.dart';
import 'package:rbac_mobile_app/core/security/permission_matrix.dart';
import 'package:rbac_mobile_app/core/security/user_role.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class AppStarted extends AuthEvent {
  const AppStarted();
}

final class LoginRequested extends AuthEvent {
  const LoginRequested({required this.identifier, required this.password});

  final String identifier;
  final String password;

  @override
  List<Object?> get props => [identifier, password];
}

final class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

/// Émis lorsque la matrice RBAC change (matrice rechargée ou permission
/// basculée par un administrateur). Le bloc ré-émet alors son état pour que les
/// gardes `go_router` soient réévaluées immédiatement.
final class PermissionsUpdated extends AuthEvent {
  const PermissionsUpdated(this.matrix);

  final PermissionMatrix matrix;

  @override
  List<Object?> get props => [matrix];
}

/// Émis lorsqu'un administrateur réaffecte un rôle. Si le compte concerné est
/// celui de la session courante, le rôle est appliqué à chaud.
final class UserRoleChanged extends AuthEvent {
  const UserRoleChanged({required this.userId, required this.role});

  final String userId;
  final UserRole role;

  @override
  List<Object?> get props => [userId, role];
}
