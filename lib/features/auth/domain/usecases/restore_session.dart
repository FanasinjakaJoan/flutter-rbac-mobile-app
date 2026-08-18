import 'package:rbac_mobile_app/features/auth/domain/entities/auth_session.dart';
import 'package:rbac_mobile_app/features/auth/domain/repositories/auth_repository.dart';

class RestoreSession {
  const RestoreSession(this._repository);

  final AuthRepository _repository;

  Future<AuthSession?> call() => _repository.restoreSession();
}
