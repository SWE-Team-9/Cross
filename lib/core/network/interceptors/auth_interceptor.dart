import 'package:dio/dio.dart';
import '../../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage secureStorage;

  AuthInterceptor({required this.secureStorage});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Don't add token for auth endpoints
    if (!options.path.contains('/auth/')) {
      final token = await secureStorage.read('access_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle 401 unauthorized errors (token expired)
    if (err.response?.statusCode == 401) {
      // TODO: Trigger token refresh or logout
    }
    handler.next(err);
  }
}