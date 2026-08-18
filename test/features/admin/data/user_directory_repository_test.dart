import 'package:flutter_test/flutter_test.dart';
import 'package:rbac_mobile_app/core/security/rbac_storage.dart';
import 'package:rbac_mobile_app/core/security/user_role.dart';
import 'package:rbac_mobile_app/features/admin/data/datasources/mock_user_directory_data_source.dart';
import 'package:rbac_mobile_app/features/admin/data/repositories/user_directory_repository_impl.dart';
import 'package:rbac_mobile_app/features/admin/domain/entities/managed_user.dart';

void main() {
  late InMemoryRbacStorage storage;
  late UserDirectoryRepositoryImpl repository;

  UserDirectoryRepositoryImpl buildRepository(InMemoryRbacStorage store) =>
      UserDirectoryRepositoryImpl(
        dataSource: const MockUserDirectoryDataSource(latency: Duration.zero),
        storage: store,
      );

  setUp(() {
    storage = InMemoryRbacStorage();
    repository = buildRepository(storage);
  });

  test('charge l’annuaire simulé', () async {
    final users = await repository.fetchUsers();

    expect(users, isNotEmpty);
    expect(
      users.where((user) => user.role == UserRole.admin),
      isNotEmpty,
    );
  });

  test('met à jour le rôle d’un compte', () async {
    final updated = await repository.updateUserRole(
      userId: 'USR-STD-001',
      role: UserRole.technician,
    );

    expect(updated.role, UserRole.technician);

    final users = await repository.fetchUsers();
    final reloaded = users.firstWhere((user) => user.id == 'USR-STD-001');
    expect(reloaded.role, UserRole.technician);
  });

  test('persiste la réaffectation entre deux instances', () async {
    await repository.updateUserRole(
      userId: 'USR-STD-002',
      role: UserRole.admin,
    );

    final freshRepository = buildRepository(storage);
    final users = await freshRepository.fetchUsers();

    expect(
      users.firstWhere((user) => user.id == 'USR-STD-002').role,
      UserRole.admin,
    );
  });

  test('ignore un stockage corrompu', () async {
    await storage.writeRoleAssignments('{{invalide');

    final users = await buildRepository(storage).fetchUsers();

    expect(
      users.firstWhere((user) => user.id == 'USR-STD-001').role,
      UserRole.student,
    );
  });

  test('lève une erreur pour un identifiant inconnu', () async {
    await expectLater(
      repository.updateUserRole(userId: 'INCONNU', role: UserRole.admin),
      throwsA(isA<StateError>()),
    );
  });

  group('ManagedUser', () {
    const user = ManagedUser(
      id: 'USR-STD-001',
      displayName: 'Lucas Martin',
      email: 'student@example.com',
      role: UserRole.student,
    );

    test('calcule les initiales', () {
      expect(user.initials, 'LM');
      expect(
        const ManagedUser(
          id: 'X',
          displayName: 'Cher',
          email: 'c@example.com',
          role: UserRole.admin,
        ).initials,
        'C',
      );
    });

    test('matches couvre le nom, l’e-mail et l’identifiant', () {
      expect(user.matches(''), isTrue);
      expect(user.matches('lucas'), isTrue);
      expect(user.matches('STUDENT@'), isTrue);
      expect(user.matches('usr-std'), isTrue);
      expect(user.matches('sofia'), isFalse);
    });
  });
}
