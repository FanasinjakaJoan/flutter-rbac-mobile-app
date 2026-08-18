import 'package:equatable/equatable.dart';
import 'package:rbac_mobile_app/core/security/user_role.dart';
import 'package:rbac_mobile_app/features/admin/domain/entities/managed_user.dart';

enum UserDirectoryStatus { initial, loading, ready, failure }

class UserDirectoryState extends Equatable {
  const UserDirectoryState({
    this.status = UserDirectoryStatus.initial,
    this.users = const [],
    this.query = '',
    this.roleFilter,
    this.errorMessage,
    this.updatingUserId,
    this.lastUpdatedUserId,
  });

  final UserDirectoryStatus status;
  final List<ManagedUser> users;
  final String query;

  /// `null` signifie « tous les rôles ».
  final UserRole? roleFilter;
  final String? errorMessage;

  /// Identifiant du compte dont le rôle est en cours de modification.
  final String? updatingUserId;

  /// Dernier compte réaffecté, utilisé pour la confirmation visuelle.
  final String? lastUpdatedUserId;

  bool get isLoading => status == UserDirectoryStatus.loading;

  /// Comptes filtrés par recherche texte puis par rôle.
  List<ManagedUser> get filteredUsers => [
        for (final user in users)
          if (user.matches(query) && (roleFilter == null || user.role == roleFilter))
            user,
      ];

  /// Répartition des comptes par rôle, affichée dans les puces de filtre.
  Map<UserRole, int> get roleCounts => {
        for (final role in UserRole.values)
          role: users.where((user) => user.role == role).length,
      };

  UserDirectoryState copyWith({
    UserDirectoryStatus? status,
    List<ManagedUser>? users,
    String? query,
    UserRole? roleFilter,
    bool clearRoleFilter = false,
    String? errorMessage,
    bool clearError = false,
    String? updatingUserId,
    bool clearUpdating = false,
    String? lastUpdatedUserId,
    bool clearLastUpdated = false,
  }) =>
      UserDirectoryState(
        status: status ?? this.status,
        users: users ?? this.users,
        query: query ?? this.query,
        roleFilter: clearRoleFilter ? null : (roleFilter ?? this.roleFilter),
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        updatingUserId:
            clearUpdating ? null : (updatingUserId ?? this.updatingUserId),
        lastUpdatedUserId: clearLastUpdated
            ? null
            : (lastUpdatedUserId ?? this.lastUpdatedUserId),
      );

  @override
  List<Object?> get props => [
        status,
        users,
        query,
        roleFilter,
        errorMessage,
        updatingUserId,
        lastUpdatedUserId,
      ];
}
