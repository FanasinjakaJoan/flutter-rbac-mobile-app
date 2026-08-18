import 'package:rbac_mobile_app/features/auth/domain/entities/auth_session.dart';

abstract interface class AuthRemoteDataSource {
  Future<AuthSession> authenticate({
    required String identifier,
    required String password,
  });

  Future<void> requestPasswordReset(String identifier);

  Future<AuthSession> sessionFromToken(String token);

  Future<bool> verifyResetCode({
    required String identifier,
    required String code,
  });
}
