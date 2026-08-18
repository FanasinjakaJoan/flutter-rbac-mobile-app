import 'package:rbac_mobile_app/core/constants/app_routes.dart';
import 'package:rbac_mobile_app/core/security/app_permission.dart';
import 'package:rbac_mobile_app/core/security/permission_matrix.dart';
import 'package:rbac_mobile_app/core/security/user_role.dart';

export 'package:rbac_mobile_app/core/security/app_permission.dart';
export 'package:rbac_mobile_app/core/security/permission_matrix.dart';

/// Règles statiques du RBAC : association route → permission et calcul de la
/// page d'atterrissage d'un rôle.
///
/// L'évaluation dynamique (« ce rôle a-t-il ce droit maintenant ? ») est
/// déléguée à la [PermissionMatrix] courante, exposée par le `RbacService`.
abstract final class RbacPolicy {
  /// Permission exigée par une route protégée, `null` si la route est libre
  /// pour tout utilisateur authentifié.
  static AppPermission? requiredPermission(String path) => switch (path) {
        AppRoutes.adminDashboard => AppPermission.viewAdminDashboard,
        AppRoutes.studentDashboard => AppPermission.viewStudentDashboard,
        AppRoutes.technicianDashboard => AppPermission.viewTechnicianDashboard,
        AppRoutes.adminUsers => AppPermission.manageUsers,
        AppRoutes.adminPermissions => AppPermission.managePermissions,
        AppRoutes.reports => AppPermission.viewReports,
        AppRoutes.profile => AppPermission.editProfile,
        _ => null,
      };

  /// Tableau de bord « naturel » d'un rôle.
  static String dashboardFor(UserRole role) => switch (role) {
        UserRole.admin => AppRoutes.adminDashboard,
        UserRole.student => AppRoutes.studentDashboard,
        UserRole.technician => AppRoutes.technicianDashboard,
      };

  /// Destination d'atterrissage réellement autorisée par [matrix].
  ///
  /// Si un administrateur retire à un rôle l'accès à son propre tableau de
  /// bord, l'utilisateur est dirigé vers la première route encore permise,
  /// puis en dernier recours vers l'écran « accès non autorisé ».
  static String landingFor(UserRole role, PermissionMatrix matrix) {
    final preferred = dashboardFor(role);
    final preferredPermission = requiredPermission(preferred);
    if (preferredPermission == null || matrix.can(role, preferredPermission)) {
      return preferred;
    }

    for (final candidate in _fallbackRoutes) {
      final permission = requiredPermission(candidate);
      if (permission != null && matrix.can(role, permission)) {
        return candidate;
      }
    }
    return AppRoutes.unauthorized;
  }

  /// Routes candidates, dans l'ordre de préférence, pour le repli ci-dessus.
  static const List<String> _fallbackRoutes = [
    AppRoutes.adminDashboard,
    AppRoutes.studentDashboard,
    AppRoutes.technicianDashboard,
    AppRoutes.adminUsers,
    AppRoutes.reports,
    AppRoutes.profile,
    AppRoutes.adminPermissions,
  ];
}
