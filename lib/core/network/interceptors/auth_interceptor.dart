import 'package:dio/dio.dart';

import '../../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.secureStorage});

  final SecureStorage secureStorage;
  Dio? _dio;

  void setDio(Dio dio) => _dio = dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.data is! FormData) {
      options.headers['Content-Type'] = 'application/json';
    }

    if (!options.path.contains('/auth/')) {
      final token = await secureStorage.read('auth_token');
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final isRefreshEndpoint = err.requestOptions.path.contains('/auth/refresh');
    final isLoginEndpoint = err.requestOptions.path.contains('/auth/login');

    if (isUnauthorized &&
        !isRefreshEndpoint &&
        !isLoginEndpoint &&
        _dio != null) {
      try {
        await _refreshToken();

        final retryResponse = await _dio!.fetch(err.requestOptions);
        return handler.resolve(retryResponse);
      } catch (_) {
        // Refresh failed — let the original error continue.
      }
    }

    handler.next(err);
  }

  Future<void> _refreshToken() async {
    await _dio!.post('/auth/refresh');
  }
}
