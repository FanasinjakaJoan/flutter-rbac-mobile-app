import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rbac_mobile_app/core/constants/app_routes.dart';
import 'package:rbac_mobile_app/core/router/app_router.dart';
import 'package:rbac_mobile_app/core/security/token_storage.dart';
import 'package:rbac_mobile_app/features/auth/data/datasources/mock_auth_remote_data_source.dart';
import 'package:rbac_mobile_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:rbac_mobile_app/features/auth/domain/usecases/login.dart';
import 'package:rbac_mobile_app/features/auth/domain/usecases/logout.dart';
import 'package:rbac_mobile_app/features/auth/domain/usecases/restore_session.dart';
import 'package:rbac_mobile_app/features/auth/presentation/bloc/auth_bloc.dart';

void main() {
  testWidgets('redirige un visiteur non authentifié vers la connexion',
      (tester) async {
    final fixture = await RouterFixture.unauthenticated(
      initialLocation: AppRoutes.adminDashboard,
    );
    addTearDown(fixture.dispose);

    await tester.pumpWidget(fixture.widget);
    await tester.pumpAndSettle();

    expect(find.text('Se connecter'), findsOneWidget);
    expect(fixture.router.router.routeInformationProvider.value.uri.path,
        AppRoutes.login);
  });

  testWidgets('redirige un étudiant hors de la route admin', (tester) async {
    final fixture = await RouterFixture.authenticated(
      identifier: 'student',
      initialLocation: AppRoutes.adminDashboard,
    );
    addTearDown(fixture.dispose);

    await tester.pumpWidget(fixture.widget);
    await tester.pumpAndSettle();

    expect(find.text('Accès non autorisé'), findsOneWidget);
    expect(fixture.router.router.routeInformationProvider.value.uri.path,
        AppRoutes.unauthorized);
  });

  testWidgets('autorise un administrateur sur son tableau de bord',
      (tester) async {
    final fixture = await RouterFixture.authenticated(
      identifier: 'admin',
      initialLocation: AppRoutes.adminDashboard,
    );
    addTearDown(fixture.dispose);

    await tester.pumpWidget(fixture.widget);
    await tester.pumpAndSettle();

    expect(find.text('Administration'), findsOneWidget);
    expect(find.text('Utilisateurs actifs'), findsOneWidget);
  });
}

class RouterFixture {
  RouterFixture._({
    required this.bloc,
    required this.repository,
    required this.router,
  });

  final AuthBloc bloc;
  final AuthRepositoryImpl repository;
  final AppRouter router;

  Widget get widget => BlocProvider.value(
        value: bloc,
        child: MaterialApp.router(routerConfig: router.router),
      );

  static Future<RouterFixture> unauthenticated({
    required String initialLocation,
  }) async {
    final fixture = _create(initialLocation);
    fixture.bloc.add(const AppStarted());
    await fixture.bloc.stream.firstWhere(
      (state) => state.status == AuthStatus.unauthenticated,
    );
    return fixture;
  }

  static Future<RouterFixture> authenticated({
    required String identifier,
    required String initialLocation,
  }) async {
    final fixture = _create(initialLocation);
    fixture.bloc.add(LoginRequested(
      identifier: identifier,
      password: 'Password123!',
    ));
    await fixture.bloc.stream.firstWhere(
      (state) => state.status == AuthStatus.authenticated,
    );
    return fixture;
  }

  static RouterFixture _create(String initialLocation) {
    final repository = AuthRepositoryImpl(
      remoteDataSource: MockAuthRemoteDataSource(latency: Duration.zero),
      tokenStorage: TestTokenStorage(),
    );
    final bloc = AuthBloc(
      login: Login(repository),
      logout: Logout(repository),
      restoreSession: RestoreSession(repository),
    );
    final router = AppRouter(
      authBloc: bloc,
      authRepository: repository,
      initialLocation: initialLocation,
    );
    return RouterFixture._(
      bloc: bloc,
      repository: repository,
      router: router,
    );
  }

  Future<void> dispose() async {
    router.dispose();
    await bloc.close();
  }
}

class TestTokenStorage implements TokenStorage {
  String? token;

  @override
  Future<void> deleteToken() async => token = null;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String token) async => this.token = token;
}
