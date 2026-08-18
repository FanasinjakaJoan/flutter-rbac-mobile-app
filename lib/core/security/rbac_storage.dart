import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rbac_mobile_app/core/constants/app_constants.dart';

/// Persistance locale des personnalisations RBAC (matrice de permissions et
/// réaffectations de rôles).
abstract interface class RbacStorage {
  Future<String?> readPermissionMatrix();

  Future<void> writePermissionMatrix(String encoded);

  Future<String?> readRoleAssignments();

  Future<void> writeRoleAssignments(String encoded);

  Future<void> clear();
}

/// Implémentation adossée à `flutter_secure_storage`.
class SecureRbacStorage implements RbacStorage {
  SecureRbacStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readPermissionMatrix() =>
      _storage.read(key: AppConstants.permissionMatrixStorageKey);

  @override
  Future<void> writePermissionMatrix(String encoded) => _storage.write(
        key: AppConstants.permissionMatrixStorageKey,
        value: encoded,
      );

  @override
  Future<String?> readRoleAssignments() =>
      _storage.read(key: AppConstants.roleAssignmentsStorageKey);

  @override
  Future<void> writeRoleAssignments(String encoded) => _storage.write(
        key: AppConstants.roleAssignmentsStorageKey,
        value: encoded,
      );

  @override
  Future<void> clear() async {
    await _storage.delete(key: AppConstants.permissionMatrixStorageKey);
    await _storage.delete(key: AppConstants.roleAssignmentsStorageKey);
  }
}

/// Implémentation mémoire utilisée par les tests et le mode démo.
class InMemoryRbacStorage implements RbacStorage {
  InMemoryRbacStorage({String? permissionMatrix, String? roleAssignments})
      : _permissionMatrix = permissionMatrix,
        _roleAssignments = roleAssignments;

  String? _permissionMatrix;
  String? _roleAssignments;

  @override
  Future<String?> readPermissionMatrix() async => _permissionMatrix;

  @override
  Future<void> writePermissionMatrix(String encoded) async =>
      _permissionMatrix = encoded;

  @override
  Future<String?> readRoleAssignments() async => _roleAssignments;

  @override
  Future<void> writeRoleAssignments(String encoded) async =>
      _roleAssignments = encoded;

  @override
  Future<void> clear() async {
    _permissionMatrix = null;
    _roleAssignments = null;
  }
}
