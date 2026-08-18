import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rbac_mobile_app/core/security/token_storage.dart';
import 'package:rbac_mobile_app/core/security/user_role.dart';
import 'package:rbac_mobile_app/features/auth/data/datasources/mock_auth_remote_data_source.dart';
import 'package:rbac_mobile_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:rbac_mobile_app/features/auth/domain/entities/app_user.dart';
import 'package:rbac_mobile_app/features/auth/domain/usecases/login.dart';
import 'package:rbac_mobile_app/features/auth/domain/usecases/logout.dart';
import 'package:rbac_mobile_app/features/auth/domain/usecases/restore_session.dart';
import 'package:rbac_mobile_app/features/auth/presentation/bloc/auth_bloc.dart';

void main() {
  late MemoryTokenStorage storage;
  late AuthRepositoryImpl repository;

  AuthBloc buildBloc() => AuthBloc(
        login: Login(repository),
        logout: Logout(repository),
        restoreSession: RestoreSession(repository),
      );

  setUp(() {
    storage = MemoryTokenStorage();
    repository = AuthRepositoryImpl(
      remoteDataSource: MockAuthRemoteDataSource(latency: Duration.zero),
      tokenStorage: storage,
    );
  });

  blocTest<AuthBloc, AuthState>(
    'démarre sans session en état non authentifié',
    build: buildBloc,
    act: (bloc) => bloc.add(const AppStarted()),
    expect: () => const [
      AuthState(status: AuthStatus.loading),
      AuthState(status: AuthStatus.unauthenticated),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'connecte un étudiant avec son matricule',
    build: buildBloc,
    act: (bloc) => bloc.add(const LoginRequested(
      identifier: 'MAT-12345',
      password: 'Password123!',
    )),
    expect: () => [
      const AuthState(status: AuthStatus.loading),
      isA<AuthState>()
          .having((state) => state.status, 'statut', AuthStatus.authenticated)
          .having((state) => state.user?.role, 'rôle', UserRole.student),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'expose une erreur après un mauvais mot de passe',
    build: buildBloc,
    act: (bloc) => bloc.add(const LoginRequested(
      identifier: 'admin',
      password: 'Mauvais123!',
    )),
    expect: () => [
      const AuthState(status: AuthStatus.loading),
      isA<AuthState>()
          .having(
            (state) => state.status,
            'statut',
            AuthStatus.unauthenticated,
          )
          .having((state) => state.errorMessage, 'erreur', isNotNull),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'efface le jeton à la déconnexion',
    build: buildBloc,
    seed: () => const AuthState(
      status: AuthStatus.authenticated,
      user: AppUser(
        id: 'USR-STD-001',
        displayName: 'Lucas Martin',
        primaryIdentifier: 'student@example.com',
        role: UserRole.student,
      ),
    ),
    setUp: () => storage.writeToken('jeton'),
    act: (bloc) => bloc.add(const LogoutRequested()),
    expect: () => [
      isA<AuthState>().having(
        (state) => state.status,
        'statut',
        AuthStatus.loading,
      ),
      const AuthState(status: AuthStatus.unauthenticated),
    ],
    verify: (_) => expect(storage.token, isNull),
  );
}

class MemoryTokenStorage implements TokenStorage {
  String? token;

  @override
  Future<void> deleteToken() async => token = null;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String token) async => this.token = token;
}
