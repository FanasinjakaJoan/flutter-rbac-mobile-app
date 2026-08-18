import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rbac_mobile_app/core/security/app_permission.dart';
import 'package:rbac_mobile_app/core/security/permission_matrix.dart';
import 'package:rbac_mobile_app/core/security/rbac_service.dart';
import 'package:rbac_mobile_app/core/security/rbac_storage.dart';
import 'package:rbac_mobile_app/core/security/user_role.dart';
import 'package:rbac_mobile_app/features/admin/presentation/cubit/permission_matrix_cubit.dart';
import 'package:rbac_mobile_app/features/admin/presentation/pages/permission_matrix_page.dart';

void main() {
  late InMemoryRbacStorage storage;
  late RbacService service;
  late PermissionMatrixCubit cubit;

  setUp(() {
    storage = InMemoryRbacStorage();
    service = RbacService(storage: storage);
    cubit = PermissionMatrixCubit(rbacService: service);
  });

  tearDown(() async {
    await cubit.close();
    await service.dispose();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    // Surface large pour éviter tout défilement horizontal dans le test.
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const PermissionMatrixPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Laisse expirer les SnackBars afin qu'aucun timer ne reste actif à la fin
  /// du test.
  Future<void> drainSnackBars(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  testWidgets('affiche une bascule pour chaque couple rôle/permission',
      (tester) async {
    await pumpPage(tester);

    expect(find.text('Matrice des permissions'), findsOneWidget);
    for (final role in UserRole.values) {
      for (final permission in AppPermission.values) {
        expect(
          find.byKey(Key('permission-${role.name}-${permission.name}')),
          findsOneWidget,
          reason: 'case manquante pour ${role.name}/${permission.name}',
        );
      }
    }
  });

  testWidgets('reflète l’état initial de la matrice', (tester) async {
    await pumpPage(tester);

    final adminManageUsers = tester.widget<Switch>(
      find.byKey(const Key('permission-admin-manageUsers')),
    );
    final studentManageUsers = tester.widget<Switch>(
      find.byKey(const Key('permission-student-manageUsers')),
    );

    expect(adminManageUsers.value, isTrue);
    expect(studentManageUsers.value, isFalse);
  });

  testWidgets('accorde une permission et la propage au service',
      (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('permission-student-viewReports')));
    await tester.pumpAndSettle();

    expect(service.can(UserRole.student, AppPermission.viewReports), isTrue);
    final toggle = tester.widget<Switch>(
      find.byKey(const Key('permission-student-viewReports')),
    );
    expect(toggle.value, isTrue);
    expect(find.textContaining('accordée à Étudiant'), findsOneWidget);
    await drainSnackBars(tester);
  });

  testWidgets('retire une permission accordée', (tester) async {
    await pumpPage(tester);

    await tester
        .tap(find.byKey(const Key('permission-technician-viewReports')));
    await tester.pumpAndSettle();

    expect(service.can(UserRole.technician, AppPermission.viewReports), isFalse);
    expect(find.textContaining('retirée à Technicien'), findsOneWidget);
    await drainSnackBars(tester);
  });

  testWidgets('verrouille la permission managePermissions de l’admin',
      (tester) async {
    await pumpPage(tester);

    final locked = tester.widget<Switch>(
      find.byKey(const Key('permission-admin-managePermissions')),
    );

    expect(locked.value, isTrue);
    expect(locked.onChanged, isNull);
  });

  testWidgets('persiste la modification dans le stockage', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('permission-student-viewReports')));
    await tester.pumpAndSettle();

    final persisted = PermissionMatrix.tryDecode(
      await storage.readPermissionMatrix(),
    );

    expect(persisted, isNotNull);
    expect(
      persisted!.can(UserRole.student, AppPermission.viewReports),
      isTrue,
    );
    await drainSnackBars(tester);
  });

  testWidgets('réinitialise la matrice aux valeurs par défaut',
      (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('permission-student-viewReports')));
    await tester.pumpAndSettle();
    expect(service.matrix.isDefault, isFalse);

    await tester.tap(find.byKey(const Key('permission-matrix-reset')));
    await tester.pumpAndSettle();

    expect(service.matrix, PermissionMatrix.defaults);
    final toggle = tester.widget<Switch>(
      find.byKey(const Key('permission-student-viewReports')),
    );
    expect(toggle.value, isFalse);
    await drainSnackBars(tester);
  });

  testWidgets('se met à jour lorsqu’une autre session modifie la matrice',
      (tester) async {
    await pumpPage(tester);

    // Modification provenant d'une autre source (ex. seconde session).
    await service.setPermission(
      role: UserRole.student,
      permission: AppPermission.viewReports,
      granted: true,
    );
    await tester.pumpAndSettle();

    final toggle = tester.widget<Switch>(
      find.byKey(const Key('permission-student-viewReports')),
    );
    expect(toggle.value, isTrue);
    await drainSnackBars(tester);
  });
}
