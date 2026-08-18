import 'package:rbac_mobile_app/core/constants/app_routes.dart';
import 'package:rbac_mobile_app/core/security/user_role.dart';

enum AppPermission {
  viewAdminDashboard,
  viewStudentDashboard,
  viewTechnicianDashboard,
}

abstract final class RbacPolicy {
  static const Map<UserRole, Set<AppPermission>> _permissions = {
    UserRole.admin: {AppPermission.viewAdminDashboard},
    UserRole.student: {AppPermission.viewStudentDashboard},
    UserRole.technician: {AppPermission.viewTechnicianDashboard},
  };

  static bool can(UserRole role, AppPermission permission) =>
      _permissions[role]?.contains(permission) ?? false;

  static AppPermission? requiredPermission(String path) => switch (path) {
        AppRoutes.adminDashboard => AppPermission.viewAdminDashboard,
        AppRoutes.studentDashboard => AppPermission.viewStudentDashboard,
        AppRoutes.technicianDashboard =>
          AppPermission.viewTechnicianDashboard,
        _ => null,
      };

  static String dashboardFor(UserRole role) => switch (role) {
        UserRole.admin => AppRoutes.adminDashboard,
        UserRole.student => AppRoutes.studentDashboard,
        UserRole.technician => AppRoutes.technicianDashboard,
      };
}
