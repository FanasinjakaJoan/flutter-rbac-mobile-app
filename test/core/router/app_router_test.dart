import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rbac_mobile_app/core/constants/app_routes.dart';
import 'package:rbac_mobile_app/core/router/app_router.dart';
import 'package:rbac_mobile_app/core/security/app_permission.dart';
import 'package:rbac_mobile_app/core/security/rbac_service.dart';
import 'package:rbac_mobile_app/core/security/rbac_storage.dart';
import 'package:rbac_mobile_app/core/security/token_storage.dart';
import 'package:rbac_mobile_app/core/security/user_role.dart';
import 'package:rbac_mobile_app/features/admin/data/datasources/mock_user_directory_data_source.dart';
import 'package:rbac_mobile_app/features/admin/data/repositories/user_directory_repository_impl.dart';
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
    expect(fixture.currentPath, AppRoutes.login);
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
    expect(fixture.currentPath, AppRoutes.unauthorized);
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

  testWidgets('autorise un administrateur sur /admin/users', (tester) async {
    final fixture = await RouterFixture.authenticated(
      identifier: 'admin',
      initialLocation: AppRoutes.adminUsers,
    );
    addTearDown(fixture.dispose);

    await tester.pumpWidget(fixture.widget);
    await tester.pumpAndSettle();

    expect(find.text('Gestion des utilisateurs'), findsOneWidget);
    expect(fixture.currentPath, AppRoutes.adminUsers);
  });

  testWidgets('autorise un administrateur sur /admin/permissions',
      (tester) async {
    final fixture = await RouterFixture.authenticated(
      identifier: 'admin',
      initialLocation: AppRoutes.adminPermissions,
    );
    addTearDown(fixture.dispose);

    await tester.pumpWidget(fixture.widget);
    await tester.pumpAndSettle();

    expect(find.text('Matrice des permissions'), findsOneWidget);
  });

  testWidgets('refuse /admin/users à un technicien', (tester) async {
    final fixture = await RouterFixture.authenticated(
      identifier: 'technician',
      initialLocation: AppRoutes.adminUsers,
    );
    addTearDown(fixture.dispose);

    await tester.pumpWidget(fixture.widget);
    await tester.pumpAndSettle();

    expect(fixture.currentPath, AppRoutes.unauthorized);
  });

  group('gardes dynamiques', () {
    testWidgets('ouvre une route dès que la permission est accordée',
        (tester) async {
      final fixture = await RouterFixture.authenticated(
        identifier: 'student',
        initialLocation: AppRoutes.studentDashboard,
      );
      addTearDown(fixture.dispose);

      await tester.pumpWidget(fixture.widget);
      await tester.pumpAndSettle();

      // Sans la permission, la route rapports est refusée.
      fixture.router.router.go(AppRoutes.reports);
      await tester.pumpAndSettle();
      expect(fixture.currentPath, AppRoutes.unauthorized);

      // Un administrateur accorde `viewReports` aux étudiants.
      await fixture.rbacService.setPermission(
        role: UserRole.student,
        permission: AppPermission.viewReports,
        granted: true,
      );
      await tester.pumpAndSettle();

      fixture.router.router.go(AppRoutes.reports);
      await tester.pumpAndSettle();

      expect(fixture.currentPath, AppRoutes.reports);
      expect(find.text('Rapports'), findsOneWidget);
    });

    testWidgets('éjecte l’utilisateur quand la permission est retirée',
        (tester) async {
      final fixture = await RouterFixture.authenticated(
        identifier: 'technician',
        initialLocation: AppRoutes.reports,
      );
      addTearDown(fixture.dispose);

      await tester.pumpWidget(fixture.widget);
      await tester.pumpAndSettle();
      expect(fixture.currentPath, AppRoutes.reports);

      // Le droit est révoqué pendant que la page est affichée.
      await fixture.rbacService.setPermission(
        role: UserRole.technician,
        permission: AppPermission.viewReports,
        granted: false,
      );
      await tester.pumpAndSettle();

      expect(fixture.currentPath, AppRoutes.unauthorized);
      expect(find.text('Accès non autorisé'), findsOneWidget);
    });

    testWidgets('redirige vers une page de repli si le tableau de bord est '
        'révoqué', (tester) async {
      final fixture = await RouterFixture.authenticated(
        identifier: 'student',
        initialLocation: AppRoutes.studentDashboard,
      );
      addTearDown(fixture.dispose);

      await tester.pumpWidget(fixture.widget);
      await tester.pumpAndSettle();

      await fixture.rbacService.setPermission(
        role: UserRole.student,
        permission: AppPermission.viewStudentDashboard,
        granted: false,
      );
      await tester.pumpAndSettle();

      expect(fixture.currentPath, AppRoutes.unauthorized);

      fixture.router.router.go(AppRoutes.root);
      await tester.pumpAndSettle();

      // `landingFor` bascule sur la première route encore autorisée.
      expect(fixture.currentPath, AppRoutes.profile);
    });
  });
}

class RouterFixture {
  RouterFixture._({
    required this.bloc,
    required this.repository,
    required this.router,
    required this.rbacService,
  });

  final AuthBloc bloc;
  final AuthRepositoryImpl repository;
  final AppRouter router;
  final RbacService rbacService;

  Widget get widget => BlocProvider.value(
        value: bloc,
        child: MaterialApp.router(routerConfig: router.router),
      );

  String get currentPath =>
      router.router.routeInformationProvider.value.uri.path;

  static Future<RouterFixture> unauthenticated({
    required String initialLocation,
  }) async {
    final fixture = _create(initialLocation);
    final ready = fixture.bloc.stream.firstWhere(
      (state) => state.status == AuthStatus.unauthenticated,
    );
    fixture.bloc.add(const AppStarted());
    await ready;
    return fixture;
  }

  static Future<RouterFixture> authenticated({
    required String identifier,
    required String initialLocation,
  }) async {
    final fixture = _create(initialLocation);
    final ready = fixture.bloc.stream.firstWhere(
      (state) => state.status == AuthStatus.authenticated,
    );
    fixture.bloc.add(LoginRequested(
      identifier: identifier,
      password: 'Password123!',
    ));
    await ready;
    return fixture;
  }

  static RouterFixture _create(String initialLocation) {
    final repository = AuthRepositoryImpl(
      remoteDataSource: MockAuthRemoteDataSource(latency: Duration.zero),
      tokenStorage: TestTokenStorage(),
    );
    final rbacStorage = InMemoryRbacStorage();
    final rbacService = RbacService(storage: rbacStorage);
    final bloc = AuthBloc(
      login: Login(repository),
      logout: Logout(repository),
      restoreSession: RestoreSession(repository),
      rbacService: rbacService,
    );
    final router = AppRouter(
      authBloc: bloc,
      authRepository: repository,
      rbacService: rbacService,
      userDirectoryRepository: UserDirectoryRepositoryImpl(
        dataSource: const MockUserDirectoryDataSource(latency: Duration.zero),
        storage: rbacStorage,
      ),
      initialLocation: initialLocation,
    );
    return RouterFixture._(
      bloc: bloc,
      repository: repository,
      router: router,
      rbacService: rbacService,
    );
  }

  Future<void> dispose() async {
    router.dispose();
    await bloc.close();
    await rbacService.dispose();
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
