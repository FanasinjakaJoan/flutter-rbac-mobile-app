import 'package:rbac_mobile_app/core/security/user_role.dart';
import 'package:rbac_mobile_app/features/admin/domain/entities/managed_user.dart';

/// Jeu de données simulé de l'annuaire.
///
/// Les trois premiers comptes correspondent aux identifiants de démonstration
/// acceptés par `MockAuthRemoteDataSource`.
abstract interface class UserDirectoryDataSource {
  Future<List<ManagedUser>> fetchUsers();
}

class MockUserDirectoryDataSource implements UserDirectoryDataSource {
  const MockUserDirectoryDataSource({
    this.latency = const Duration(milliseconds: 320),
  });

  final Duration latency;

  static const List<ManagedUser> seed = [
    ManagedUser(
      id: 'USR-ADM-001',
      displayName: 'Amina Diallo',
      email: 'admin@example.com',
      role: UserRole.admin,
    ),
    ManagedUser(
      id: 'USR-STD-001',
      displayName: 'Lucas Martin',
      email: 'student@example.com',
      role: UserRole.student,
    ),
    ManagedUser(
      id: 'USR-TEC-001',
      displayName: 'Sofia Bernard',
      email: 'technician@example.com',
      role: UserRole.technician,
    ),
    ManagedUser(
      id: 'USR-STD-002',
      displayName: 'Nirina Rakoto',
      email: 'nirina.rakoto@example.com',
      role: UserRole.student,
    ),
    ManagedUser(
      id: 'USR-STD-003',
      displayName: 'Hery Andriamana',
      email: 'hery.andriamana@example.com',
      role: UserRole.student,
    ),
    ManagedUser(
      id: 'USR-TEC-002',
      displayName: 'Paul Rivière',
      email: 'paul.riviere@example.com',
      role: UserRole.technician,
    ),
    ManagedUser(
      id: 'USR-ADM-002',
      displayName: 'Chloé Dupont',
      email: 'chloe.dupont@example.com',
      role: UserRole.admin,
    ),
    ManagedUser(
      id: 'USR-STD-004',
      displayName: 'Mamy Rasoa',
      email: 'mamy.rasoa@example.com',
      role: UserRole.student,
      isActive: false,
    ),
  ];

  @override
  Future<List<ManagedUser>> fetchUsers() async {
    await Future<void>.delayed(latency);
    return List<ManagedUser>.from(seed);
  }
}
