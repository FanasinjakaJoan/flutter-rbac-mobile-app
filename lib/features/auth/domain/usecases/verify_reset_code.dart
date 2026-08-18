import 'package:rbac_mobile_app/features/auth/domain/repositories/auth_repository.dart';

class VerifyResetCode {
  const VerifyResetCode(this._repository);

  final AuthRepository _repository;

  Future<bool> call({required String identifier, required String code}) =>
      _repository.verifyResetCode(identifier: identifier, code: code);
}
