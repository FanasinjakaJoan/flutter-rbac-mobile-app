enum UserRole {
  admin,
  student,
  technician;

  String get label => switch (this) {
        UserRole.admin => 'Administrateur',
        UserRole.student => 'Étudiant',
        UserRole.technician => 'Technicien',
      };

  static UserRole fromValue(String value) => switch (value.toLowerCase()) {
        'admin' => UserRole.admin,
        'student' => UserRole.student,
        'technician' => UserRole.technician,
        _ => throw ArgumentError.value(value, 'value', 'Rôle inconnu'),
      };
}
