import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rbac_mobile_app/core/security/app_permission.dart';
import 'package:rbac_mobile_app/core/security/permission_matrix.dart';
import 'package:rbac_mobile_app/core/security/rbac_service.dart';
import 'package:rbac_mobile_app/core/security/user_role.dart';

class PermissionMatrixState extends Equatable {
  const PermissionMatrixState({
    required this.matrix,
    this.pending,
    this.feedback,
  });

  final PermissionMatrix matrix;

  /// Couple rôle/permission en cours d'écriture (affiche un indicateur).
  final (UserRole, AppPermission)? pending;

  /// Message de confirmation affiché après une bascule.
  final String? feedback;

  bool get isDefault => matrix.isDefault;

  bool isPending(UserRole role, AppPermission permission) =>
      pending != null && pending!.$1 == role && pending!.$2 == permission;

  PermissionMatrixState copyWith({
    PermissionMatrix? matrix,
    (UserRole, AppPermission)? pending,
    bool clearPending = false,
    String? feedback,
    bool clearFeedback = false,
  }) =>
      PermissionMatrixState(
        matrix: matrix ?? this.matrix,
        pending: clearPending ? null : (pending ?? this.pending),
        feedback: clearFeedback ? null : (feedback ?? this.feedback),
      );

  @override
  List<Object?> get props => [matrix, pending, feedback];
}

/// Pilote la matrice interactive `/admin/permissions`.
///
/// Chaque bascule est déléguée au [RbacService], qui persiste puis rediffuse la
/// nouvelle matrice ; le cubit se réaligne sur ce flux, ce qui garantit qu'un
/// seul état fait autorité.
class PermissionMatrixCubit extends Cubit<PermissionMatrixState> {
  PermissionMatrixCubit({required RbacService rbacService})
      : _rbacService = rbacService,
        super(PermissionMatrixState(matrix: rbacService.matrix)) {
    _subscription = _rbacService.changes.listen((matrix) {
      if (isClosed) {
        return;
      }
      emit(state.copyWith(matrix: matrix, clearPending: true));
    });
  }

  final RbacService _rbacService;
  late final StreamSubscription<PermissionMatrix> _subscription;

  /// Bascule un droit. Les couples verrouillés sont refusés avec un message.
  Future<void> toggle({
    required UserRole role,
    required AppPermission permission,
  }) async {
    if (PermissionMatrix.isLocked(role, permission)) {
      emit(state.copyWith(
        feedback:
            'La permission « ${permission.label} » est verrouillée pour le rôle ${role.label}.',
      ));
      return;
    }

    final granted = !state.matrix.can(role, permission);
    emit(state.copyWith(pending: (role, permission), clearFeedback: true));
    final matrix = await _rbacService.setPermission(
      role: role,
      permission: permission,
      granted: granted,
    );
    if (isClosed) {
      return;
    }
    emit(state.copyWith(
      matrix: matrix,
      clearPending: true,
      feedback: granted
          ? '« ${permission.label} » accordée à ${role.label}.'
          : '« ${permission.label} » retirée à ${role.label}.',
    ));
  }

  Future<void> resetToDefaults() async {
    final matrix = await _rbacService.resetToDefaults();
    if (isClosed) {
      return;
    }
    emit(state.copyWith(
      matrix: matrix,
      clearPending: true,
      feedback: 'Matrice réinitialisée aux valeurs par défaut.',
    ));
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
