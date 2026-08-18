import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rbac_mobile_app/core/error/auth_exception.dart';
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
  })  : _login = login,
        _logout = logout,
        _restoreSession = restoreSession,
        super(const AuthState.initial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  final Login _login;
  final Logout _logout;
  final RestoreSession _restoreSession;

  Future<void> _onAppStarted(
    AppStarted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState(status: AuthStatus.loading));
    try {
      final session = await _restoreSession();
      if (session == null) {
        emit(const AuthState(status: AuthStatus.unauthenticated));
      } else {
        emit(AuthState(
          status: AuthStatus.authenticated,
          user: session.user,
        ));
      }
    } on Object {
      emit(const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Impossible de restaurer la session.',
      ));
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState(status: AuthStatus.loading));
    try {
      final session = await _login(
        identifier: event.identifier,
        password: event.password,
      );
      emit(AuthState(
        status: AuthStatus.authenticated,
        user: session.user,
      ));
    } on AuthException catch (error) {
      emit(AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: error.message,
      ));
    } on Object {
      emit(const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Une erreur inattendue est survenue.',
      ));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentUser = state.user;
    emit(AuthState(status: AuthStatus.loading, user: currentUser));
    try {
      await _logout();
      emit(const AuthState(status: AuthStatus.unauthenticated));
    } on Object {
      emit(AuthState(
        status: AuthStatus.authenticated,
        user: currentUser,
        errorMessage: 'La déconnexion a échoué. Réessayez.',
      ));
    }
  }
}
