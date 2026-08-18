import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rbac_mobile_app/core/constants/app_routes.dart';
import 'package:rbac_mobile_app/core/router/router_refresh_notifier.dart';
import 'package:rbac_mobile_app/core/security/rbac_policy.dart';
import 'package:rbac_mobile_app/core/security/rbac_service.dart';
import 'package:rbac_mobile_app/core/security/user_role.dart';
import 'package:rbac_mobile_app/features/admin/domain/repositories/user_directory_repository.dart';
import 'package:rbac_mobile_app/features/admin/presentation/cubit/permission_matrix_cubit.dart';
import 'package:rbac_mobile_app/features/admin/presentation/cubit/user_directory_cubit.dart';
import 'package:rbac_mobile_app/features/admin/presentation/pages/permission_matrix_page.dart';
import 'package:rbac_mobile_app/features/admin/presentation/pages/user_management_page.dart';
import 'package:rbac_mobile_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:rbac_mobile_app/features/auth/domain/usecases/request_password_reset.dart';
import 'package:rbac_mobile_app/features/auth/domain/usecases/verify_reset_code.dart';
import 'package:rbac_mobile_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:rbac_mobile_app/features/auth/presentation/cubit/password_recovery_cubit.dart';
import 'package:rbac_mobile_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:rbac_mobile_app/features/auth/presentation/pages/login_page.dart';
import 'package:rbac_mobile_app/features/auth/presentation/pages/reset_code_page.dart';
import 'package:rbac_mobile_app/features/auth/presentation/pages/splash_page.dart';
import 'package:rbac_mobile_app/features/auth/presentation/pages/unauthorized_page.dart';
import 'package:rbac_mobile_app/features/dashboard/presentation/pages/admin_dashboard_page.dart';
import 'package:rbac_mobile_app/features/dashboard/presentation/pages/student_dashboard_page.dart';
import 'package:rbac_mobile_app/features/dashboard/presentation/pages/technician_dashboard_page.dart';
import 'package:rbac_mobile_app/features/profile/presentation/pages/profile_page.dart';
import 'package:rbac_mobile_app/features/reports/presentation/pages/reports_page.dart';

class AppRouter {
  AppRouter({
    required AuthBloc authBloc,
    required AuthRepository authRepository,
    required RbacService rbacService,
    required UserDirectoryRepository userDirectoryRepository,
    String initialLocation = AppRoutes.root,
  })  : _authBloc = authBloc,
        _authRepository = authRepository,
        _rbacService = rbacService,
        _userDirectoryRepository = userDirectoryRepository {
    // Le routeur écoute à la fois les changements d'authentification et les
    // changements de matrice RBAC : une permission retirée déclenche donc
    // immédiatement une réévaluation des gardes.
    _refreshNotifier = RouterRefreshNotifier.merge([
      authBloc.stream,
      rbacService.changes,
    ]);
    router = GoRouter(
      initialLocation: initialLocation,
      refreshListenable: _refreshNotifier,
      redirect: _redirect,
      routes: [
        GoRoute(
          path: AppRoutes.root,
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (context, state) => BlocProvider(
            create: (_) => _createPasswordRecoveryCubit(),
            child: const ForgotPasswordPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.resetCode,
          builder: (context, state) => BlocProvider(
            create: (_) => _createPasswordRecoveryCubit(),
            child: ResetCodePage(
              identifier: state.uri.queryParameters['identifier'] ?? '',
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.unauthorized,
          builder: (context, state) => const UnauthorizedPage(),
        ),
        GoRoute(
          path: AppRoutes.adminDashboard,
          builder: (context, state) => const AdminDashboardPage(),
        ),
        GoRoute(
          path: AppRoutes.studentDashboard,
          builder: (context, state) => const StudentDashboardPage(),
        ),
        GoRoute(
          path: AppRoutes.technicianDashboard,
          builder: (context, state) => const TechnicianDashboardPage(),
        ),
        GoRoute(
          path: AppRoutes.adminUsers,
          builder: (context, state) => BlocProvider(
            create: (_) => UserDirectoryCubit(
              repository: _userDirectoryRepository,
              authBloc: _authBloc,
            )..loadUsers(),
            child: const UserManagementPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.adminPermissions,
          builder: (context, state) => BlocProvider(
            create: (_) => PermissionMatrixCubit(rbacService: _rbacService),
            child: const PermissionMatrixPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.reports,
          builder: (context, state) => const ReportsPage(),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => const ProfilePage(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded, size: 64),
              const SizedBox(height: 16),
              Text(
                'Page introuvable',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go(AppRoutes.root),
                child: const Text('Retour à l’accueil'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  final AuthBloc _authBloc;
  final AuthRepository _authRepository;
  final RbacService _rbacService;
  final UserDirectoryRepository _userDirectoryRepository;
  late final RouterRefreshNotifier _refreshNotifier;
  late final GoRouter router;

  static const _publicPaths = {
    AppRoutes.login,
    AppRoutes.forgotPassword,
    AppRoutes.resetCode,
  };

  PasswordRecoveryCubit _createPasswordRecoveryCubit() =>
      PasswordRecoveryCubit(
        requestPasswordReset: RequestPasswordReset(_authRepository),
        verifyResetCode: VerifyResetCode(_authRepository),
      );

  String? _redirect(BuildContext context, GoRouterState routerState) {
    final authState = _authBloc.state;
    final matrix = _rbacService.matrix;
    final path = routerState.uri.path;
    final isWaiting = authState.status == AuthStatus.initial ||
        authState.status == AuthStatus.loading;

    if (isWaiting) {
      if (authState.user != null || _publicPaths.contains(path)) {
        return null;
      }
      if (path == AppRoutes.splash) {
        return null;
      }
      if (path == AppRoutes.root) {
        return AppRoutes.splash;
      }
      final destination = Uri.encodeComponent(routerState.uri.toString());
      return '${AppRoutes.splash}?from=$destination';
    }

    if (!authState.isAuthenticated) {
      if (_publicPaths.contains(path)) {
        return null;
      }
      final restoredDestination = path == AppRoutes.splash
          ? routerState.uri.queryParameters['from']
          : null;
      final destination = restoredDestination ??
          (path == AppRoutes.root ? null : routerState.uri.toString());
      final from = destination == null
          ? ''
          : '?from=${Uri.encodeComponent(destination)}';
      return '${AppRoutes.login}$from';
    }

    final user = authState.user!;
    if (path == AppRoutes.login || path == AppRoutes.splash) {
      return _destinationFor(
        user.role,
        routerState.uri.queryParameters['from'],
      );
    }

    if (_publicPaths.contains(path) || path == AppRoutes.root) {
      return RbacPolicy.landingFor(user.role, matrix);
    }

    // Garde dynamique : la permission est relue dans la matrice courante à
    // chaque navigation ET à chaque notification du refreshListenable.
    final requiredPermission = RbacPolicy.requiredPermission(path);
    if (requiredPermission != null &&
        !matrix.can(user.role, requiredPermission)) {
      return AppRoutes.unauthorized;
    }
    return null;
  }

  String _destinationFor(UserRole role, String? destination) {
    final matrix = _rbacService.matrix;
    if (destination == null ||
        !destination.startsWith('/') ||
        destination.startsWith('//')) {
      return RbacPolicy.landingFor(role, matrix);
    }
    final destinationPath = Uri.parse(destination).path;
    final permission = RbacPolicy.requiredPermission(destinationPath);
    if (permission != null && !matrix.can(role, permission)) {
      return AppRoutes.unauthorized;
    }
    if (_publicPaths.contains(destinationPath) ||
        destinationPath == AppRoutes.root ||
        destinationPath == AppRoutes.splash) {
      return RbacPolicy.landingFor(role, matrix);
    }
    return destination;
  }

  void dispose() {
    router.dispose();
    _refreshNotifier.dispose();
  }
}
