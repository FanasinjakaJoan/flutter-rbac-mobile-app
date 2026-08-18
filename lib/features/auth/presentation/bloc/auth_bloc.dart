import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rbac_mobile_app/core/error/auth_exception.dart';
import 'package:rbac_mobile_app/core/security/permission_matrix.dart';
import 'package:rbac_mobile_app/core/security/rbac_service.dart';
import 'package:rbac_mobile_app/features/auth/domain/entities/app_user.dart';
import 'package:rbac_mobile_app/features/auth/domain/usecases/login.dart';
import 'package:rbac_mobile_app/features/auth/domain/usecases/logout.dart';
import 'package:rbac_mobile_app/features/auth/domain/usecases/restore_session.dart';
import 'package:rbac_mobile_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:rbac_mobile_app/features/auth/presentation/bloc/auth_state.dart';

export 'auth_event.dart';
export 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required Login login,
    required Logout logout,
    required RestoreSession restoreSession,
    RbacService? rbacService,
  })  : _login = login,
        _logout = logout,
        _restoreSession = restoreSession,
        _rbacService = rbacService,
        super(
          AuthState(
            status: AuthStatus.initial,
            permissions: rbacService?.matrix ?? PermissionMatrix.defaults,
          ),
        ) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<PermissionsUpdated>(_onPermissionsUpdated);
    on<UserRoleChanged>(_onUserRoleChanged);

    // Toute mise à jour de la matrice est réinjectée dans le bloc : l'état est
    // ré-émis, `RouterRefreshNotifier` se déclenche et les gardes de routage
    // sont réévaluées sans redémarrer l'application.
    final service = _rbacService;
    if (service != null) {
      _matrixSubscription = service.changes.listen(
        (matrix) => add(PermissionsUpdated(matrix)),
      );
    }
  }

  final Login _login;
  final Logout _logout;
  final RestoreSession _restoreSession;
  final RbacService? _rbacService;
  StreamSubscription<PermissionMatrix>? _matrixSubscription;

  PermissionMatrix get _currentMatrix =>
      _rbacService?.matrix ?? state.permissions;

  Future<void> _onAppStarted(
    AppStarted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthState(
      status: AuthStatus.loading,
      permissions: _currentMatrix,
    ));
    try {
      await _rbacService?.load();
      final session = await _restoreSession();
      if (session == null) {
        emit(AuthState(
          status: AuthStatus.unauthenticated,
          permissions: _currentMatrix,
        ));
      } else {
        emit(AuthState(
          status: AuthStatus.authenticated,
          user: session.user,
          permissions: _currentMatrix,
        ));
      }
    } on Object {
      emit(AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Impossible de restaurer la session.',
        permissions: _currentMatrix,
      ));
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthState(
      status: AuthStatus.loading,
      permissions: _currentMatrix,
    ));
    try {
      final session = await _login(
        identifier: event.identifier,
        password: event.password,
      );
      emit(AuthState(
        status: AuthStatus.authenticated,
        user: session.user,
        permissions: _currentMatrix,
      ));
    } on AuthException catch (error) {
      emit(AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: error.message,
        permissions: _currentMatrix,
      ));
    } on Object {
      emit(AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Une erreur inattendue est survenue.',
        permissions: _currentMatrix,
      ));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentUser = state.user;
    emit(AuthState(
      status: AuthStatus.loading,
      user: currentUser,
      permissions: _currentMatrix,
    ));
    try {
      await _logout();
      emit(AuthState(
        status: AuthStatus.unauthenticated,
        permissions: _currentMatrix,
      ));
    } on Object {
      emit(AuthState(
        status: AuthStatus.authenticated,
        user: currentUser,
        errorMessage: 'La déconnexion a échoué. Réessayez.',
        permissions: _currentMatrix,
      ));
    }
  }

  /// Diffuse la nouvelle matrice à la session courante.
  void _onPermissionsUpdated(
    PermissionsUpdated event,
    Emitter<AuthState> emit,
  ) {
    if (state.permissions == event.matrix) {
      return;
    }
    emit(state.copyWith(permissions: event.matrix, clearError: true));
  }

  /// Applique à chaud une réaffectation de rôle qui concerne la session active.
  void _onUserRoleChanged(
    UserRoleChanged event,
    Emitter<AuthState> emit,
  ) {
    final current = state.user;
    if (current == null || current.id != event.userId) {
      return;
    }
    if (current.role == event.role) {
      return;
    }
    emit(state.copyWith(
      user: AppUser(
        id: current.id,
        displayName: current.displayName,
        primaryIdentifier: current.primaryIdentifier,
        role: event.role,
      ),
      clearError: true,
    ));
  }

  @override
  Future<void> close() async {
    await _matrixSubscription?.cancel();
    return super.close();
  }
}
