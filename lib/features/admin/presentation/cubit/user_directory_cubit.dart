import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rbac_mobile_app/core/security/user_role.dart';
import 'package:rbac_mobile_app/features/admin/domain/repositories/user_directory_repository.dart';
import 'package:rbac_mobile_app/features/admin/presentation/cubit/user_directory_state.dart';
import 'package:rbac_mobile_app/features/auth/presentation/bloc/auth_bloc.dart';

export 'user_directory_state.dart';

/// Pilote l'écran `/admin/users` : chargement, recherche, filtrage par rôle et
/// réaffectation de rôle.
class UserDirectoryCubit extends Cubit<UserDirectoryState> {
  UserDirectoryCubit({
    required UserDirectoryRepository repository,
    AuthBloc? authBloc,
  })  : _repository = repository,
        _authBloc = authBloc,
        super(const UserDirectoryState());

  final UserDirectoryRepository _repository;
  final AuthBloc? _authBloc;

  Future<void> loadUsers() async {
    emit(state.copyWith(
      status: UserDirectoryStatus.loading,
      clearError: true,
    ));
    try {
      final users = await _repository.fetchUsers();
      emit(state.copyWith(
        status: UserDirectoryStatus.ready,
        users: users,
        clearError: true,
      ));
    } on Object {
      emit(state.copyWith(
        status: UserDirectoryStatus.failure,
        errorMessage: 'Impossible de charger l’annuaire des utilisateurs.',
      ));
    }
  }

  void search(String query) => emit(state.copyWith(query: query));

  /// `null` réinitialise le filtre sur « tous les rôles ».
  void filterByRole(UserRole? role) => emit(
        role == null
            ? state.copyWith(clearRoleFilter: true)
            : state.copyWith(roleFilter: role),
      );

  /// Réaffecte un rôle, persiste le changement puis notifie `AuthBloc` afin
  /// que la session concernée applique le nouveau rôle immédiatement.
  Future<void> changeRole({
    required String userId,
    required UserRole role,
  }) async {
    emit(state.copyWith(
      updatingUserId: userId,
      clearError: true,
      clearLastUpdated: true,
    ));
    try {
      final updated = await _repository.updateUserRole(
        userId: userId,
        role: role,
      );
      final users = [
        for (final user in state.users)
          if (user.id == updated.id) updated else user,
      ];
      emit(state.copyWith(
        status: UserDirectoryStatus.ready,
        users: users,
        clearUpdating: true,
        lastUpdatedUserId: updated.id,
      ));
      _authBloc?.add(UserRoleChanged(userId: updated.id, role: updated.role));
    } on Object {
      emit(state.copyWith(
        clearUpdating: true,
        errorMessage: 'La mise à jour du rôle a échoué. Réessayez.',
      ));
    }
  }
}
