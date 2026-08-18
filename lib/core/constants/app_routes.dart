abstract final class AppRoutes {
  static const root = '/';
  static const splash = '/splash';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const resetCode = '/reset-code';
  static const unauthorized = '/unauthorized';
  static const adminDashboard = '/admin/dashboard';
  static const studentDashboard = '/student/dashboard';
  static const technicianDashboard = '/technician/dashboard';

  /// Écran d'administration listant les comptes et permettant la réaffectation
  /// de rôle.
  static const adminUsers = '/admin/users';

  /// Matrice interactive rôles × permissions.
  static const adminPermissions = '/admin/permissions';

  /// Rapports d'activité, protégés par `viewReports`.
  static const reports = '/reports';

  /// Profil utilisateur, protégé par `editProfile`.
  static const profile = '/profile';
}
