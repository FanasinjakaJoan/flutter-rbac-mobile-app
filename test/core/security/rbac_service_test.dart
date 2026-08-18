import 'package:flutter_test/flutter_test.dart';
import 'package:rbac_mobile_app/core/constants/app_routes.dart';
import 'package:rbac_mobile_app/core/security/app_permission.dart';
import 'package:rbac_mobile_app/core/security/permission_matrix.dart';
import 'package:rbac_mobile_app/core/security/rbac_policy.dart';
import 'package:rbac_mobile_app/core/security/rbac_service.dart';
import 'package:rbac_mobile_app/core/security/rbac_storage.dart';
import 'package:rbac_mobile_app/core/security/user_role.dart';

void main() {
  late InMemoryRbacStorage storage;
  late RbacService service;

  setUp(() {
    storage = InMemoryRbacStorage();
    service = RbacService(storage: storage);
  });

  tearDown(() => service.dispose());

  group('RbacService — cycle de vie', () {
    test('démarre sur la matrice par défaut', () {
      expect(service.matrix, PermissionMatrix.defaults);
      expect(service.isLoaded, isFalse);
    });

    test('restaure la matrice persistée au chargement', () async {
      final customized = PermissionMatrix.defaults.toggle(
        role: UserRole.student,
        permission: AppPermission.viewReports,
      );
      await storage.writePermissionMatrix(customized.encode());

      final loaded = await service.load();

      expect(loaded, customized);
      expect(service.isLoaded, isTrue);
      expect(service.can(UserRole.student, AppPermission.viewReports), isTrue);
    });

    test('retombe sur les valeurs par défaut si le stockage est corrompu',
        () async {
      await storage.writePermissionMatrix('<<corrompu>>');

      final loaded = await service.load();

      expect(loaded, PermissionMatrix.defaults);
    });
  });

  group('RbacService — mises à jour', () {
    test('persiste chaque modification', () async {
      await service.setPermission(
        role: UserRole.student,
        permission: AppPermission.viewReports,
        granted: true,
      );

      final persisted = PermissionMatrix.tryDecode(
        await storage.readPermissionMatrix(),
      );

      expect(persisted, isNotNull);
      expect(persisted!.can(UserRole.student, AppPermission.viewReports), isTrue);
    });

    test('diffuse la nouvelle matrice sur le flux changes', () async {
      final emitted = <PermissionMatrix>[];
      final subscription = service.changes.listen(emitted.add);

      await service.toggle(
        role: UserRole.student,
        permission: AppPermission.viewReports,
      );
      await service.toggle(
        role: UserRole.technician,
        permission: AppPermission.editProfile,
      );
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(emitted, hasLength(2));
      expect(
        emitted.first.can(UserRole.student, AppPermission.viewReports),
        isTrue,
      );
      expect(
        emitted.last.can(UserRole.technician, AppPermission.editProfile),
        isFalse,
      );
    });

    test('n’émet rien lorsque la modification est sans effet', () async {
      final emitted = <PermissionMatrix>[];
      final subscription = service.changes.listen(emitted.add);

      // Déjà accordée par défaut : aucun changement.
      await service.setPermission(
        role: UserRole.admin,
        permission: AppPermission.manageUsers,
        granted: true,
      );
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(emitted, isEmpty);
    });

    test('resetToDefaults restaure la matrice d’usine', () async {
      await service.toggle(
        role: UserRole.student,
        permission: AppPermission.viewReports,
      );
      expect(service.matrix.isDefault, isFalse);

      await service.resetToDefaults();

      expect(service.matrix, PermissionMatrix.defaults);
    });
  });

  group('RbacPolicy — routage dynamique', () {
    test('associe chaque route protégée à sa permission', () {
      expect(
        RbacPolicy.requiredPermission(AppRoutes.adminUsers),
        AppPermission.manageUsers,
      );
      expect(
        RbacPolicy.requiredPermission(AppRoutes.adminPermissions),
        AppPermission.managePermissions,
      );
      expect(
        RbacPolicy.requiredPermission(AppRoutes.reports),
        AppPermission.viewReports,
      );
      expect(RbacPolicy.requiredPermission(AppRoutes.login), isNull);
    });

    test('landingFor privilégie le tableau de bord du rôle', () {
      expect(
        RbacPolicy.landingFor(UserRole.student, PermissionMatrix.defaults),
        AppRoutes.studentDashboard,
      );
    });

    test('landingFor bascule sur une route de repli autorisée', () {
      final matrix = PermissionMatrix.defaults.setPermission(
        role: UserRole.student,
        permission: AppPermission.viewStudentDashboard,
        granted: false,
      );

      expect(
        RbacPolicy.landingFor(UserRole.student, matrix),
        AppRoutes.profile,
        reason: 'editProfile reste la seule route accessible',
      );
    });

    test('landingFor renvoie vers l’écran non autorisé sans aucun droit', () {
      final matrix = PermissionMatrix.defaults.replaceRole(
        UserRole.student,
        const <AppPermission>[],
      );

      expect(
        RbacPolicy.landingFor(UserRole.student, matrix),
        AppRoutes.unauthorized,
      );
    });
  });
}
