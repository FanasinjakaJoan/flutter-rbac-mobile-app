import 'package:dio/dio.dart';
import 'package:rbac_mobile_app/core/network/dio_client.dart';
import 'package:rbac_mobile_app/core/security/rbac_service.dart';
import 'package:rbac_mobile_app/core/security/rbac_storage.dart';
import 'package:rbac_mobile_app/core/security/token_storage.dart';
import 'package:rbac_mobile_app/features/admin/data/datasources/mock_user_directory_data_source.dart';
import 'package:rbac_mobile_app/features/admin/data/repositories/user_directory_repository_impl.dart';
import 'package:rbac_mobile_app/features/admin/domain/repositories/user_directory_repository.dart';
import 'package:rbac_mobile_app/features/auth/data/datasources/mock_auth_remote_data_source.dart';
import 'package:rbac_mobile_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:rbac_mobile_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:rbac_mobile_app/features/auth/domain/usecases/login.dart';
import 'package:rbac_mobile_app/features/auth/domain/usecases/logout.dart';
import 'package:rbac_mobile_app/features/auth/domain/usecases/restore_session.dart';
import 'package:rbac_mobile_app/features/auth/presentation/bloc/auth_bloc.dart';

class AppDependencies {
  const AppDependencies({
    required this.dio,
    required this.authRepository,
    required this.authBloc,
    required this.rbacService,
    required this.userDirectoryRepository,
  });

  factory AppDependencies.bootstrap() {
    final tokenStorage = SecureTokenStorage();
    final rbacStorage = SecureRbacStorage();
    final dio = DioClient.create(tokenStorage);
    final authRepository = AuthRepositoryImpl(
      remoteDataSource: MockAuthRemoteDataSource(),
      tokenStorage: tokenStorage,
    );
    final rbacService = RbacService(storage: rbacStorage);
    final userDirectoryRepository = UserDirectoryRepositoryImpl(
      dataSource: const MockUserDirectoryDataSource(),
      storage: rbacStorage,
    );
    // `AppStarted` restaure la matrice RBAC puis la session : les gardes de
    // routage disposent donc des bonnes permissions dès le premier redirect.
    final authBloc = AuthBloc(
      login: Login(authRepository),
      logout: Logout(authRepository),
      restoreSession: RestoreSession(authRepository),
      rbacService: rbacService,
    )..add(const AppStarted());

    return AppDependencies(
      dio: dio,
      authRepository: authRepository,
      authBloc: authBloc,
      rbacService: rbacService,
      userDirectoryRepository: userDirectoryRepository,
    );
  }

  final Dio dio;
  final AuthRepository authRepository;
  final AuthBloc authBloc;
  final RbacService rbacService;
  final UserDirectoryRepository userDirectoryRepository;
}
