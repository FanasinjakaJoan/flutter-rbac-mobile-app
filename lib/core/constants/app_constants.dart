abstract final class AppConstants {
  static const appName = 'Portail RBAC';
  static const tokenStorageKey = 'rbac_access_token';
  static const permissionMatrixStorageKey = 'rbac_permission_matrix';
  static const roleAssignmentsStorageKey = 'rbac_role_assignments';
  static const mockApiBaseUrl = 'https://mock-api.rbac.local';
  static const requestTimeout = Duration(seconds: 15);
}
