import 'package:dio/dio.dart';
import 'package:rbac_mobile_app/core/constants/app_constants.dart';
import 'package:rbac_mobile_app/core/network/auth_interceptor.dart';
import 'package:rbac_mobile_app/core/security/token_storage.dart';

abstract final class DioClient {
  static Dio create(TokenStorage tokenStorage) {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.mockApiBaseUrl,
        connectTimeout: AppConstants.requestTimeout,
        receiveTimeout: AppConstants.requestTimeout,
        contentType: Headers.jsonContentType,
      ),
    );
    dio.interceptors.add(AuthInterceptor(tokenStorage));
    return dio;
  }
}
