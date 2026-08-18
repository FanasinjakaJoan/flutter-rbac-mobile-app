import 'package:flutter_test/flutter_test.dart';
import 'package:rbac_mobile_app/core/security/app_permission.dart';
import 'package:rbac_mobile_app/core/security/permission_matrix.dart';
import 'package:rbac_mobile_app/core/security/rbac_service.dart';
import 'package:rbac_mobile_app/core/security/rbac_storage.dart';
import 'package:rbac_mobile_app/core/security/token_storage.dart';
import 'package:rbac_mobile_app/core/security/user_role.dart';
import 'package:rbac_mobile_app/features/auth/data/datasources/mock_auth_remote_data_source.dart';
import 'package:rbac_mobile_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:rbac_mobile_app/features/auth/domain/usecases/login.dart';
import 'package:rbac_mobile_app/features/auth/domain/usecases/logout.dart';
import 'package:rbac_mobile_app/features/auth/domain/usecases/restore_session.dart';
import 'package:rbac_mobile_app/features/auth/presentation/bloc/auth_bloc.dart';

void main() {
  late InMemoryRbacStorage rbacStorage;
  late RbacService rbacService;
  late AuthBloc bloc;

  setUp(() {
    rbacStorage = InMemoryRbacStorage();
    rbacService = RbacService(storage: rbacStorage);
    final repository = AuthRepositoryImpl(
      remoteDataSource: MockAuthRemoteDataSource(latency: Duration.zero),
      tokenStorage: _InMemoryTokenStorage(),
    );
    bloc = AuthBloc(
      login: Login(repository),
      logout: Logout(repository),
      restoreSession: RestoreSession(repository),
      rbacService: rbacService,
    );
  });

  tearDown(() async {
    await bloc.close();
    await rbacService.dispose();
  });

  Future<void> loginAs(String identifier) async {
    final authenticated = bloc.stream.firstWhere(
      (state) => state.status == AuthStatus.authenticated,
    );
    bloc.add(LoginRequested(identifier: identifier, password: 'Password123!'));
    await authenticated;
  }

  test('expose les permissions du rôle connecté', () async {
    await loginAs('admin');

    expect(bloc.state.can(AppPermission.manageUsers), isTrue);
    expect(bloc.state.can(AppPermission.viewStudentDashboard), isFalse);
  });

  test('diffuse immédiatement une permission accordée par un admin', () async {
    await loginAs('student');
    expect(bloc.state.can(AppPermission.viewReports), isFalse);

    // L'abonnement est ouvert avant la modification pour éviter toute course.
    final broadcast =
        bloc.stream.firstWhere((state) => state.can(AppPermission.viewReports));
    await rbacService.setPermission(
      role: UserRole.student,
      permission: AppPermission.viewReports,
      granted: true,
    );
    await broadcast;

    expect(bloc.state.can(AppPermission.viewReports), isTrue);
    expect(bloc.state.status, AuthStatus.authenticated);
  });

  test('diffuse immédiatement une permission retirée', () async {
    await loginAs('technician');
    expect(bloc.state.can(AppPermission.viewReports), isTrue);

    final broadcast = bloc.stream
        .firstWhere((state) => !state.can(AppPermission.viewReports));
    await rbacService.setPermission(
      role: UserRole.technician,
      permission: AppPermission.viewReports,
      granted: false,
    );
    await broadcast;

    expect(bloc.state.can(AppPermission.viewReports), isFalse);
    expect(bloc.state.user, isNotNull);
  });

  test('charge la matrice persistée au démarrage', () async {
    final customized = PermissionMatrix.defaults.toggle(
      role: UserRole.student,
      permission: AppPermission.viewReports,
    );
    await rbacStorage.writePermissionMatrix(customized.encode());

    final started = bloc.stream.firstWhere(
      (state) => state.status == AuthStatus.unauthenticated,
    );
    bloc.add(const AppStarted());
    await started;
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.permissions, customized);
  });

  group('UserRoleChanged', () {
    test('applique le nouveau rôle à la session concernée', () async {
      await loginAs('student');
      final userId = bloc.state.user!.id;

      final reassigned = bloc.stream
          .firstWhere((state) => state.user?.role == UserRole.technician);
      bloc.add(UserRoleChanged(userId: userId, role: UserRole.technician));
      await reassigned;

      expect(bloc.state.user!.role, UserRole.technician);
      expect(bloc.state.can(AppPermission.viewTechnicianDashboard), isTrue);
      expect(bloc.state.can(AppPermission.viewStudentDashboard), isFalse);
    });

    test('ignore la réaffectation d’un autre compte', () async {
      await loginAs('student');
      final before = bloc.state;

      bloc.add(
        const UserRoleChanged(userId: 'USR-AUTRE-999', role: UserRole.admin),
      );
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, before);
    });
  });
}

class _InMemoryTokenStorage implements TokenStorage {
  String? _token;

  @override
  Future<void> deleteToken() async => _token = null;

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> writeToken(String token) async => _token = token;
}
