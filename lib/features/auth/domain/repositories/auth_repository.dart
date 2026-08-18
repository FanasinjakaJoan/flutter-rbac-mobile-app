import 'package:rbac_mobile_app/features/auth/domain/entities/auth_session.dart';

abstract interface class AuthRepository {
  Future<AuthSession> login({
    required String identifier,
    required String password,
  });

  Future<void> logout();

  Future<void> requestPasswordReset(String identifier);

  Future<AuthSession?> restoreSession();

  Future<bool> verifyResetCode({
    required String identifier,
    required String code,
  });
}
