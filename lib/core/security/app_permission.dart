/// Catalogue des permissions applicatives évaluées par le moteur RBAC.
///
/// Chaque permission est associée à un écran ou à une action métier. Les
/// gardes de routage (`go_router`) et les widgets consomment cette énumération
/// via la [PermissionMatrix] active.
enum AppPermission {
  viewAdminDashboard,
  viewStudentDashboard,
  viewTechnicianDashboard,
  manageUsers,
  managePermissions,
  viewReports,
  editProfile;

  /// Libellé court affiché dans la matrice d'administration.
  String get label => switch (this) {
        AppPermission.viewAdminDashboard => 'Tableau de bord admin',
        AppPermission.viewStudentDashboard => 'Tableau de bord étudiant',
        AppPermission.viewTechnicianDashboard => 'Console technicien',
        AppPermission.manageUsers => 'Gérer les utilisateurs',
        AppPermission.managePermissions => 'Gérer les permissions',
        AppPermission.viewReports => 'Consulter les rapports',
        AppPermission.editProfile => 'Modifier son profil',
      };

  /// Description fonctionnelle utilisée comme aide contextuelle.
  String get description => switch (this) {
        AppPermission.viewAdminDashboard =>
          'Accès à la vue d’ensemble de l’administration.',
        AppPermission.viewStudentDashboard =>
          'Accès à l’espace pédagogique de l’étudiant.',
        AppPermission.viewTechnicianDashboard =>
          'Accès à la file d’intervention technique.',
        AppPermission.manageUsers =>
          'Lister, rechercher et réaffecter le rôle des comptes.',
        AppPermission.managePermissions =>
          'Modifier la matrice rôles / permissions en temps réel.',
        AppPermission.viewReports =>
          'Consulter les rapports d’activité et d’audit.',
        AppPermission.editProfile =>
          'Mettre à jour ses informations personnelles.',
      };

  /// Analyse tolérante utilisée à la désérialisation du stockage local.
  static AppPermission? tryParse(String value) {
    final normalized = value.trim();
    for (final permission in AppPermission.values) {
      if (permission.name == normalized) {
        return permission;
      }
    }
    return null;
  }
}
