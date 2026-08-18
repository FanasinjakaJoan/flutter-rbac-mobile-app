import 'dart:async';

import 'package:rbac_mobile_app/core/security/app_permission.dart';
import 'package:rbac_mobile_app/core/security/permission_matrix.dart';
import 'package:rbac_mobile_app/core/security/rbac_storage.dart';
import 'package:rbac_mobile_app/core/security/user_role.dart';

/// Source de vérité runtime du RBAC.
///
/// Le service détient la [PermissionMatrix] courante, la persiste et diffuse
/// chaque modification via [changes]. `AuthBloc` s'y abonne pour ré-émettre un
/// état, ce qui fait réévaluer les gardes `go_router` sur toutes les sessions
/// actives sans redémarrage.
class RbacService {
  RbacService({
    required RbacStorage storage,
    PermissionMatrix? initialMatrix,
  })  : _storage = storage,
        _matrix = initialMatrix ?? PermissionMatrix.defaults;

  final RbacStorage _storage;
  final StreamController<PermissionMatrix> _controller =
      StreamController<PermissionMatrix>.broadcast();

  PermissionMatrix _matrix;
  bool _isLoaded = false;

  /// Matrice active à cet instant.
  PermissionMatrix get matrix => _matrix;

  /// Vrai une fois la matrice restaurée depuis le stockage local.
  bool get isLoaded => _isLoaded;

  /// Flux diffusant chaque nouvelle version de la matrice.
  Stream<PermissionMatrix> get changes => _controller.stream;

  /// Restaure la matrice persistée. Retombe silencieusement sur les valeurs
  /// par défaut si le stockage est vide ou corrompu.
  Future<PermissionMatrix> load() async {
    try {
      final restored = PermissionMatrix.tryDecode(
        await _storage.readPermissionMatrix(),
      );
      if (restored != null) {
        _matrix = restored;
      }
    } on Object {
      _matrix = PermissionMatrix.defaults;
    }
    _isLoaded = true;
    _controller.add(_matrix);
    return _matrix;
  }

  /// Évalue une permission avec la matrice courante.
  bool can(UserRole role, AppPermission permission) =>
      _matrix.can(role, permission);

  /// Accorde ou retire une permission puis diffuse et persiste le résultat.
  Future<PermissionMatrix> setPermission({
    required UserRole role,
    required AppPermission permission,
    required bool granted,
  }) =>
      _commit(
        _matrix.setPermission(
          role: role,
          permission: permission,
          granted: granted,
        ),
      );

  /// Inverse l'état d'un couple rôle/permission.
  Future<PermissionMatrix> toggle({
    required UserRole role,
    required AppPermission permission,
  }) =>
      _commit(_matrix.toggle(role: role, permission: permission));

  /// Remplace l'ensemble des permissions d'un rôle.
  Future<PermissionMatrix> replaceRole(
    UserRole role,
    Iterable<AppPermission> permissions,
  ) =>
      _commit(_matrix.replaceRole(role, permissions));

  /// Restaure la matrice d'usine.
  Future<PermissionMatrix> resetToDefaults() =>
      _commit(PermissionMatrix.defaults, force: true);

  Future<PermissionMatrix> _commit(
    PermissionMatrix next, {
    bool force = false,
  }) async {
    if (!force && next == _matrix) {
      return _matrix;
    }
    _matrix = next;
    _controller.add(_matrix);
    try {
      await _storage.writePermissionMatrix(_matrix.encode());
    } on Object {
      // La persistance est « best effort » : une écriture échouée ne doit pas
      // annuler la mise à jour déjà diffusée aux sessions actives.
    }
    return _matrix;
  }

  Future<void> dispose() => _controller.close();
}
