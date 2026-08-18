import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rbac_mobile_app/core/security/user_role.dart';
import 'package:rbac_mobile_app/features/admin/data/datasources/mock_user_directory_data_source.dart';
import 'package:rbac_mobile_app/features/admin/domain/entities/managed_user.dart';
import 'package:rbac_mobile_app/features/admin/domain/repositories/user_directory_repository.dart';
import 'package:rbac_mobile_app/features/admin/presentation/cubit/user_directory_cubit.dart';
import 'package:rbac_mobile_app/features/admin/presentation/pages/user_management_page.dart';
import 'package:rbac_mobile_app/features/admin/presentation/widgets/role_assignment_dialog.dart';

void main() {
  late _FakeUserDirectoryRepository repository;
  late UserDirectoryCubit cubit;

  setUp(() {
    repository = _FakeUserDirectoryRepository();
    cubit = UserDirectoryCubit(repository: repository);
  });

  tearDown(() => cubit.close());

  Future<void> pumpPage(WidgetTester tester) async {
    // L'annuaire est chargé avant le premier pump pour éviter toute émission
    // pendant la construction de l'arbre.
    await cubit.loadUsers();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const UserManagementPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Laisse expirer les SnackBars pour ne pas laisser de timer en suspens.
  Future<void> drainSnackBars(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  testWidgets('affiche la liste des comptes', (tester) async {
    await pumpPage(tester);

    expect(find.text('Gestion des utilisateurs'), findsOneWidget);
    expect(find.byKey(const Key('user-card-USR-ADM-001')), findsOneWidget);
    expect(find.byKey(const Key('user-card-USR-STD-001')), findsOneWidget);
    expect(find.text('Amina Diallo'), findsOneWidget);
  });

  testWidgets('filtre la liste par recherche texte', (tester) async {
    await pumpPage(tester);

    await tester.enterText(find.byKey(const Key('user-search-field')), 'sofia');
    await tester.pumpAndSettle();

    expect(find.text('Sofia Bernard'), findsOneWidget);
    expect(find.text('Amina Diallo'), findsNothing);
  });

  testWidgets('affiche un état vide sans résultat', (tester) async {
    await pumpPage(tester);

    await tester.enterText(
      find.byKey(const Key('user-search-field')),
      'aucun-resultat-possible',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('user-list-empty')), findsOneWidget);
  });

  testWidgets('filtre la liste par rôle', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('role-filter-technician')));
    await tester.pumpAndSettle();

    expect(find.text('Sofia Bernard'), findsOneWidget);
    expect(find.text('Paul Rivière'), findsOneWidget);
    expect(find.text('Lucas Martin'), findsNothing);

    await tester.tap(find.byKey(const Key('role-filter-all')));
    await tester.pumpAndSettle();

    expect(find.text('Lucas Martin'), findsOneWidget);
  });

  testWidgets('réaffecte un rôle via la boîte de dialogue', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('edit-role-USR-STD-001')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('role-assignment-dialog')), findsOneWidget);

    await tester.tap(find.byKey(const Key('role-option-technician')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('role-assignment-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('role-assignment-dialog')), findsNothing);
    expect(repository.updates, [('USR-STD-001', UserRole.technician)]);
    expect(
      cubit.state.users.firstWhere((user) => user.id == 'USR-STD-001').role,
      UserRole.technician,
    );
    await drainSnackBars(tester);
  });

  testWidgets('le bouton Enregistrer reste inactif sans changement',
      (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('edit-role-USR-STD-001')));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('role-assignment-confirm')),
    );
    expect(button.onPressed, isNull);
  });

  group('RoleAssignmentDialog', () {
    testWidgets('retourne le rôle sélectionné', (tester) async {
      UserRole? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await RoleAssignmentDialog.show(
                    context,
                    const ManagedUser(
                      id: 'USR-STD-001',
                      displayName: 'Lucas Martin',
                      email: 'student@example.com',
                      role: UserRole.student,
                    ),
                  );
                },
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('role-option-admin')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('role-assignment-confirm')));
      await tester.pumpAndSettle();

      expect(result, UserRole.admin);
    });

    testWidgets('retourne null à l’annulation', (tester) async {
      UserRole? result = UserRole.student;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await RoleAssignmentDialog.show(
                    context,
                    const ManagedUser(
                      id: 'USR-STD-001',
                      displayName: 'Lucas Martin',
                      email: 'student@example.com',
                      role: UserRole.student,
                    ),
                  );
                },
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('role-option-admin')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });
}

class _FakeUserDirectoryRepository implements UserDirectoryRepository {
  _FakeUserDirectoryRepository()
      : _users = List<ManagedUser>.from(MockUserDirectoryDataSource.seed);

  final List<ManagedUser> _users;
  final List<(String, UserRole)> updates = [];

  @override
  Future<List<ManagedUser>> fetchUsers() async => List<ManagedUser>.from(_users);

  @override
  Future<ManagedUser> updateUserRole({
    required String userId,
    required UserRole role,
  }) async {
    updates.add((userId, role));
    final index = _users.indexWhere((user) => user.id == userId);
    if (index == -1) {
      throw StateError('Utilisateur introuvable : $userId');
    }
    final updated = _users[index].copyWith(role: role);
    _users[index] = updated;
    return updated;
  }
}
