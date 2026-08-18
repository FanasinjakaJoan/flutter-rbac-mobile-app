import 'package:flutter_test/flutter_test.dart';
import 'package:rbac_mobile_app/core/security/app_permission.dart';
import 'package:rbac_mobile_app/core/security/permission_matrix.dart';
import 'package:rbac_mobile_app/core/security/user_role.dart';

void main() {
  group('PermissionMatrix — évaluation', () {
    test('applique les droits par défaut de chaque rôle', () {
      const matrix = PermissionMatrix.defaults;

      expect(matrix.can(UserRole.admin, AppPermission.manageUsers), isTrue);
      expect(matrix.can(UserRole.admin, AppPermission.viewAdminDashboard),
          isTrue);
      expect(matrix.can(UserRole.student, AppPermission.manageUsers), isFalse);
      expect(matrix.can(UserRole.student, AppPermission.viewStudentDashboard),
          isTrue);
      expect(matrix.can(UserRole.technician, AppPermission.viewReports), isTrue);
      expect(
        matrix.can(UserRole.technician, AppPermission.viewAdminDashboard),
        isFalse,
      );
    });

    test('permissionsOf conserve l’ordre de l’énumération', () {
      final permissions =
          PermissionMatrix.defaults.permissionsOf(UserRole.admin).toList();
      final expectedOrder = [
        for (final permission in AppPermission.values)
          if (permissions.contains(permission)) permission,
      ];

      expect(permissions, expectedOrder);
    });

    test('grantedCount additionne les droits de tous les rôles', () {
      const matrix = PermissionMatrix.defaults;
      final expected = UserRole.values.fold<int>(
        0,
        (total, role) => total + matrix.permissionsOf(role).length,
      );

      expect(matrix.grantedCount, expected);
    });
  });

  group('PermissionMatrix — mise à jour dynamique', () {
    test('accorde une permission absente sans muter l’instance initiale', () {
      const initial = PermissionMatrix.defaults;

      final updated = initial.setPermission(
        role: UserRole.student,
        permission: AppPermission.viewReports,
        granted: true,
      );

      expect(updated.can(UserRole.student, AppPermission.viewReports), isTrue);
      expect(initial.can(UserRole.student, AppPermission.viewReports), isFalse);
    });

    test('retire une permission accordée', () {
      final updated = PermissionMatrix.defaults.setPermission(
        role: UserRole.technician,
        permission: AppPermission.viewReports,
        granted: false,
      );

      expect(
        updated.can(UserRole.technician, AppPermission.viewReports),
        isFalse,
      );
    });

    test('toggle inverse l’état courant', () {
      const initial = PermissionMatrix.defaults;

      final once = initial.toggle(
        role: UserRole.student,
        permission: AppPermission.viewReports,
      );
      final twice = once.toggle(
        role: UserRole.student,
        permission: AppPermission.viewReports,
      );

      expect(once.can(UserRole.student, AppPermission.viewReports), isTrue);
      expect(twice, initial);
    });

    test('refuse de retirer une permission verrouillée', () {
      expect(
        PermissionMatrix.isLocked(
          UserRole.admin,
          AppPermission.managePermissions,
        ),
        isTrue,
      );

      final updated = PermissionMatrix.defaults.setPermission(
        role: UserRole.admin,
        permission: AppPermission.managePermissions,
        granted: false,
      );

      expect(
        updated.can(UserRole.admin, AppPermission.managePermissions),
        isTrue,
      );
      expect(updated, PermissionMatrix.defaults);
    });

    test('replaceRole réécrit les droits en conservant les verrous', () {
      final updated = PermissionMatrix.defaults.replaceRole(
        UserRole.admin,
        [AppPermission.viewReports],
      );

      expect(updated.can(UserRole.admin, AppPermission.viewReports), isTrue);
      expect(updated.can(UserRole.admin, AppPermission.manageUsers), isFalse);
      expect(
        updated.can(UserRole.admin, AppPermission.managePermissions),
        isTrue,
        reason: 'la permission verrouillée doit survivre au remplacement',
      );
    });

    test('isDefault distingue la matrice d’usine des personnalisations', () {
      expect(PermissionMatrix.defaults.isDefault, isTrue);
      expect(
        PermissionMatrix.defaults
            .toggle(
              role: UserRole.student,
              permission: AppPermission.viewReports,
            )
            .isDefault,
        isFalse,
      );
    });
  });

  group('PermissionMatrix — sérialisation', () {
    test('effectue un aller-retour JSON sans perte', () {
      final matrix = PermissionMatrix.defaults
          .toggle(role: UserRole.student, permission: AppPermission.viewReports)
          .toggle(
            role: UserRole.technician,
            permission: AppPermission.editProfile,
          );

      final restored = PermissionMatrix.tryDecode(matrix.encode());

      expect(restored, matrix);
    });

    test('ignore les rôles et permissions inconnus', () {
      final restored = PermissionMatrix.fromJson({
        'admin': ['manageUsers', 'permissionFantome'],
        'roleInexistant': ['manageUsers'],
      });

      expect(restored.can(UserRole.admin, AppPermission.manageUsers), isTrue);
      expect(restored.can(UserRole.student, AppPermission.manageUsers), isFalse);
      expect(
        restored.can(UserRole.admin, AppPermission.managePermissions),
        isTrue,
        reason: 'le verrou est réappliqué à la désérialisation',
      );
    });

    test('retourne null pour une entrée vide ou corrompue', () {
      expect(PermissionMatrix.tryDecode(null), isNull);
      expect(PermissionMatrix.tryDecode('   '), isNull);
      expect(PermissionMatrix.tryDecode('{pas du json'), isNull);
      expect(PermissionMatrix.tryDecode('[1,2,3]'), isNull);
    });
  });
}
