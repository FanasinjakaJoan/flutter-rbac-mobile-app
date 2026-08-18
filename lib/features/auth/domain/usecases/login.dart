import 'package:rbac_mobile_app/features/auth/domain/entities/auth_session.dart';
import 'package:rbac_mobile_app/features/auth/domain/repositories/auth_repository.dart';

class Login {
  const Login(this._repository);

  final AuthRepository _repository;

  Future<AuthSession> call({
    required String identifier,
    required String password,
  }) =>
      _repository.login(identifier: identifier, password: password);
}
