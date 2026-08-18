import 'package:rbac_mobile_app/core/security/user_role.dart';
import 'package:rbac_mobile_app/features/admin/domain/entities/managed_user.dart';

/// Accès à l'annuaire des comptes gérés par l'administration.
abstract interface class UserDirectoryRepository {
  /// Liste complète des comptes, réaffectations locales déjà appliquées.
  Future<List<ManagedUser>> fetchUsers();

  /// Change le rôle d'un compte et retourne la version mise à jour.
  Future<ManagedUser> updateUserRole({
    required String userId,
    required UserRole role,
  });
}
