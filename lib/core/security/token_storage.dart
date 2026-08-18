import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rbac_mobile_app/core/constants/app_constants.dart';

abstract interface class TokenStorage {
  Future<void> deleteToken();

  Future<String?> readToken();

  Future<void> writeToken(String token);
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> deleteToken() =>
      _storage.delete(key: AppConstants.tokenStorageKey);

  @override
  Future<String?> readToken() =>
      _storage.read(key: AppConstants.tokenStorageKey);

  @override
  Future<void> writeToken(String token) => _storage.write(
        key: AppConstants.tokenStorageKey,
        value: token,
      );
}
