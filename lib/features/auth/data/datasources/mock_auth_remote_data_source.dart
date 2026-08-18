import 'dart:convert';

import 'package:rbac_mobile_app/core/error/auth_exception.dart';
import 'package:rbac_mobile_app/core/security/user_role.dart';
import 'package:rbac_mobile_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:rbac_mobile_app/features/auth/data/models/app_user_model.dart';
import 'package:rbac_mobile_app/features/auth/domain/entities/auth_session.dart';

class MockAuthRemoteDataSource implements AuthRemoteDataSource {
  MockAuthRemoteDataSource({
    this.latency = const Duration(milliseconds: 550),
  });

  final Duration latency;

  static const _accounts = <_MockAccount>[
    _MockAccount(
      user: AppUserModel(
        id: 'USR-ADM-001',
        displayName: 'Amina Diallo',
        primaryIdentifier: 'admin@example.com',
        role: UserRole.admin,
      ),
      identifiers: {'admin@example.com', 'admin', 'adm-001'},
      password: 'Password123!',
    ),
    _MockAccount(
      user: AppUserModel(
        id: 'USR-STD-001',
        displayName: 'Lucas Martin',
        primaryIdentifier: 'student@example.com',
        role: UserRole.student,
      ),
      identifiers: {'student@example.com', 'student', 'mat-12345'},
      password: 'Password123!',
    ),
    _MockAccount(
      user: AppUserModel(
        id: 'USR-TEC-001',
        displayName: 'Sofia Bernard',
        primaryIdentifier: 'technician@example.com',
        role: UserRole.technician,
      ),
      identifiers: {'technician@example.com', 'technician', 'tec-001'},
      password: 'Password123!',
    ),
  ];

  @override
  Future<AuthSession> authenticate({
    required String identifier,
    required String password,
  }) async {
    await Future<void>.delayed(latency);
    final account = _findAccount(identifier);
    if (account == null || account.password != password) {
      throw const AuthException(
        'invalid_credentials',
        'Identifiant ou mot de passe incorrect.',
      );
    }

    return AuthSession(
      accessToken: _createMockJwt(account.user),
      user: account.user,
    );
  }

  @override
  Future<void> requestPasswordReset(String identifier) async {
    await Future<void>.delayed(latency);
    if (_findAccount(identifier) == null) {
      throw const AuthException(
        'account_not_found',
        'Aucun compte ne correspond à cet identifiant.',
      );
    }
  }

  @override
  Future<AuthSession> sessionFromToken(String token) async {
    await Future<void>.delayed(latency);
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        throw const FormatException();
      }
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      final expiresAt = payload['exp'] as int;
      if (DateTime.now().millisecondsSinceEpoch ~/ 1000 >= expiresAt) {
        throw const AuthException(
          'session_expired',
          'Votre session a expiré. Veuillez vous reconnecter.',
        );
      }

      final account = _findAccountById(payload['sub'] as String);
      if (account == null || account.user.role.name != payload['role']) {
        throw const FormatException();
      }
      return AuthSession(accessToken: token, user: account.user);
    } on AuthException {
      rethrow;
    } on Object {
      throw const AuthException(
        'invalid_token',
        'La session enregistrée est invalide.',
      );
    }
  }

  @override
  Future<bool> verifyResetCode({
    required String identifier,
    required String code,
  }) async {
    await Future<void>.delayed(latency);
    if (_findAccount(identifier) == null) {
      throw const AuthException(
        'account_not_found',
        'Aucun compte ne correspond à cet identifiant.',
      );
    }
    return code == '123456';
  }

  _MockAccount? _findAccount(String identifier) {
    final normalized = identifier.trim().toLowerCase();
    for (final account in _accounts) {
      if (account.identifiers.contains(normalized)) {
        return account;
      }
    }
    return null;
  }

  _MockAccount? _findAccountById(String id) {
    for (final account in _accounts) {
      if (account.user.id == id) {
        return account;
      }
    }
    return null;
  }

  String _createMockJwt(AppUserModel user) {
    final header = _encode({'alg': 'HS256', 'typ': 'JWT'});
    final payload = _encode({
      'sub': user.id,
      'role': user.role.name,
      'name': user.displayName,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp': DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch ~/
          1000,
    });
    return '$header.$payload.mock-signature';
  }

  String _encode(Map<String, Object> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
}

class _MockAccount {
  const _MockAccount({
    required this.user,
    required this.identifiers,
    required this.password,
  });

  final AppUserModel user;
  final Set<String> identifiers;
  final String password;
}
