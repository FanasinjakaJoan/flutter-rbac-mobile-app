import 'package:rbac_mobile_app/features/auth/domain/repositories/auth_repository.dart';

class RequestPasswordReset {
  const RequestPasswordReset(this._repository);

  final AuthRepository _repository;

  Future<void> call(String identifier) =>
      _repository.requestPasswordReset(identifier);
}
