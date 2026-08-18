import 'package:rbac_mobile_app/core/error/auth_exception.dart';
import 'package:rbac_mobile_app/core/security/token_storage.dart';
import 'package:rbac_mobile_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:rbac_mobile_app/features/auth/domain/entities/auth_session.dart';
import 'package:rbac_mobile_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required TokenStorage tokenStorage,
  })  : _remoteDataSource = remoteDataSource,
        _tokenStorage = tokenStorage;

  final AuthRemoteDataSource _remoteDataSource;
  final TokenStorage _tokenStorage;

  @override
  Future<AuthSession> login({
    required String identifier,
    required String password,
  }) async {
    final session = await _remoteDataSource.authenticate(
      identifier: identifier.trim(),
      password: password,
    );
    await _tokenStorage.writeToken(session.accessToken);
    return session;
  }

  @override
  Future<void> logout() => _tokenStorage.deleteToken();

  @override
  Future<void> requestPasswordReset(String identifier) =>
      _remoteDataSource.requestPasswordReset(identifier.trim());

  @override
  Future<AuthSession?> restoreSession() async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      return await _remoteDataSource.sessionFromToken(token);
    } on AuthException {
      await _tokenStorage.deleteToken();
      return null;
    }
  }

  @override
  Future<bool> verifyResetCode({
    required String identifier,
    required String code,
  }) =>
      _remoteDataSource.verifyResetCode(
        identifier: identifier.trim(),
        code: code.trim(),
      );
}
