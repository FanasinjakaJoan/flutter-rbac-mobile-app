import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:rbac_mobile_app/core/security/app_permission.dart';
import 'package:rbac_mobile_app/core/security/user_role.dart';

/// Représentation immuable de la matrice « rôles × permissions ».
///
/// La matrice est la source de vérité du RBAC : les gardes de routage, les
/// widgets et les tests l'interrogent via [can]. Toute modification produit une
/// nouvelle instance, ce qui permet de la diffuser dans un `Stream` et de
/// déclencher un rafraîchissement de `go_router`.
class PermissionMatrix extends Equatable {
  const PermissionMatrix(Map<UserRole, Set<AppPermission>> grants)
      : _grants = grants;

  /// Matrice appliquée au premier démarrage, avant toute personnalisation.
  static const PermissionMatrix defaults = PermissionMatrix({
    UserRole.admin: {
      AppPermission.viewAdminDashboard,
      AppPermission.manageUsers,
      AppPermission.managePermissions,
      AppPermission.viewReports,
      AppPermission.editProfile,
    },
    UserRole.student: {
      AppPermission.viewStudentDashboard,
      AppPermission.editProfile,
    },
    UserRole.technician: {
      AppPermission.viewTechnicianDashboard,
      AppPermission.viewReports,
      AppPermission.editProfile,
    },
  });

  final Map<UserRole, Set<AppPermission>> _grants;

  /// Permissions verrouillées : elles ne peuvent pas être retirées afin
  /// d'éviter qu'un administrateur ne se prive lui-même de l'écran qui permet
  /// de rétablir les droits.
  static bool isLocked(UserRole role, AppPermission permission) =>
      role == UserRole.admin && permission == AppPermission.managePermissions;

  /// Évalue une permission pour un rôle donné.
  bool can(UserRole role, AppPermission permission) =>
      _grants[role]?.contains(permission) ?? false;

  /// Permissions accordées à [role], triées selon l'ordre de l'énumération.
  Set<AppPermission> permissionsOf(UserRole role) {
    final granted = _grants[role] ?? const <AppPermission>{};
    return {
      for (final permission in AppPermission.values)
        if (granted.contains(permission)) permission,
    };
  }

  /// Nombre total de droits accordés, utilisé par les indicateurs de l'UI.
  int get grantedCount =>
      UserRole.values.fold(0, (total, role) => total + permissionsOf(role).length);

  /// Retourne une nouvelle matrice où [permission] est accordée ou retirée.
  ///
  /// Les couples verrouillés ([isLocked]) restent toujours accordés.
  PermissionMatrix setPermission({
    required UserRole role,
    required AppPermission permission,
    required bool granted,
  }) {
    if (!granted && isLocked(role, permission)) {
      return this;
    }
    final next = <UserRole, Set<AppPermission>>{
      for (final entry in UserRole.values)
        entry: {...permissionsOf(entry)},
    };
    if (granted) {
      next[role]!.add(permission);
    } else {
      next[role]!.remove(permission);
    }
    return PermissionMatrix(next);
  }

  /// Inverse l'état courant du couple rôle/permission.
  PermissionMatrix toggle({
    required UserRole role,
    required AppPermission permission,
  }) =>
      setPermission(
        role: role,
        permission: permission,
        granted: !can(role, permission),
      );

  /// Remplace intégralement les permissions d'un rôle.
  PermissionMatrix replaceRole(UserRole role, Iterable<AppPermission> values) {
    final next = <UserRole, Set<AppPermission>>{
      for (final entry in UserRole.values) entry: {...permissionsOf(entry)},
    };
    next[role] = {
      ...values,
      for (final permission in AppPermission.values)
        if (isLocked(role, permission)) permission,
    };
    return PermissionMatrix(next);
  }

  /// Vrai lorsque la matrice correspond exactement à [defaults].
  bool get isDefault => this == defaults;

  Map<String, List<String>> toJson() => {
        for (final role in UserRole.values)
          role.name: [for (final permission in permissionsOf(role)) permission.name],
      };

  String encode() => jsonEncode(toJson());

  /// Reconstruit une matrice à partir du stockage local.
  ///
  /// Les rôles ou permissions inconnus (schéma plus ancien ou plus récent) sont
  /// ignorés, ce qui rend la désérialisation tolérante aux migrations.
  static PermissionMatrix fromJson(Map<String, dynamic> json) {
    final grants = <UserRole, Set<AppPermission>>{};
    for (final role in UserRole.values) {
      final raw = json[role.name];
      final values = raw is List ? raw : const <dynamic>[];
      grants[role] = {
        for (final value in values)
          if (value is String && AppPermission.tryParse(value) != null)
            AppPermission.tryParse(value)!,
        for (final permission in AppPermission.values)
          if (isLocked(role, permission)) permission,
      };
    }
    return PermissionMatrix(grants);
  }

  static PermissionMatrix? tryDecode(String? source) {
    if (source == null || source.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return PermissionMatrix.fromJson(decoded);
    } on FormatException {
      return null;
    }
  }

  @override
  List<Object?> get props => [
        for (final role in UserRole.values) permissionsOf(role).toList(),
      ];

  @override
  String toString() => 'PermissionMatrix(${toJson()})';
}
