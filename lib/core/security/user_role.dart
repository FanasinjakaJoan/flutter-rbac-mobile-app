enum UserRole {
  admin,
  student,
  technician;

  String get label => switch (this) {
        UserRole.admin => 'Administrateur',
        UserRole.student => 'Étudiant',
        UserRole.technician => 'Technicien',
      };

  /// Libellé compact utilisé dans les puces et les en-têtes de matrice.
  String get shortLabel => switch (this) {
        UserRole.admin => 'Admin',
        UserRole.student => 'Étudiant',
        UserRole.technician => 'Technicien',
      };

  static UserRole fromValue(String value) {
    final role = tryParse(value);
    if (role == null) {
      throw ArgumentError.value(value, 'value', 'Rôle inconnu');
    }
    return role;
  }

  /// Analyse tolérante (retourne `null` au lieu de lever) pour les données
  /// persistées localement.
  static UserRole? tryParse(String value) => switch (value.trim().toLowerCase()) {
        'admin' => UserRole.admin,
        'student' => UserRole.student,
        'technician' => UserRole.technician,
        _ => null,
      };
}
