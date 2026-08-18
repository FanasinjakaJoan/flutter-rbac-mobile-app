import 'dart:convert';

import 'package:rbac_mobile_app/core/security/rbac_storage.dart';
import 'package:rbac_mobile_app/core/security/user_role.dart';
import 'package:rbac_mobile_app/features/admin/data/datasources/mock_user_directory_data_source.dart';
import 'package:rbac_mobile_app/features/admin/domain/entities/managed_user.dart';
import 'package:rbac_mobile_app/features/admin/domain/repositories/user_directory_repository.dart';

/// Annuaire mock + surcouche de réaffectations persistées localement.
///
/// La source distante reste immuable ; les changements de rôle décidés par un
/// administrateur sont stockés sous forme de dictionnaire `userId -> role`
/// dans [RbacStorage] et rejoués à chaque lecture.
class UserDirectoryRepositoryImpl implements UserDirectoryRepository {
  UserDirectoryRepositoryImpl({
    required UserDirectoryDataSource dataSource,
    required RbacStorage storage,
  })  : _dataSource = dataSource,
        _storage = storage;

  final UserDirectoryDataSource _dataSource;
  final RbacStorage _storage;

  Map<String, UserRole>? _overrides;

  @override
  Future<List<ManagedUser>> fetchUsers() async {
    final users = await _dataSource.fetchUsers();
    final overrides = await _loadOverrides();
    return [
      for (final user in users)
        overrides.containsKey(user.id)
            ? user.copyWith(role: overrides[user.id])
            : user,
    ];
  }

  @override
  Future<ManagedUser> updateUserRole({
    required String userId,
    required UserRole role,
  }) async {
    final users = await fetchUsers();
    final index = users.indexWhere((user) => user.id == userId);
    if (index == -1) {
      throw StateError('Utilisateur introuvable : $userId');
    }
    final current = users[index];

    final overrides = await _loadOverrides();
    overrides[userId] = role;
    _overrides = overrides;
    await _persistOverrides(overrides);
    return current.copyWith(role: role);
  }

  Future<Map<String, UserRole>> _loadOverrides() async {
    final cached = _overrides;
    if (cached != null) {
      return Map<String, UserRole>.from(cached);
    }

    final overrides = <String, UserRole>{};
    try {
      final raw = await _storage.readRoleAssignments();
      if (raw != null && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          decoded.forEach((key, value) {
            if (value is String) {
              final role = UserRole.tryParse(value);
              if (role != null) {
                overrides[key] = role;
              }
            }
          });
        }
      }
    } on Object {
      overrides.clear();
    }

    _overrides = Map<String, UserRole>.from(overrides);
    return overrides;
  }

  Future<void> _persistOverrides(Map<String, UserRole> overrides) async {
    try {
      await _storage.writeRoleAssignments(
        jsonEncode({
          for (final entry in overrides.entries) entry.key: entry.value.name,
        }),
      );
    } on Object {
      // Persistance best effort : l'état mémoire reste correct.
    }
  }
}
