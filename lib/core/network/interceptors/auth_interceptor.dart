import 'package:dio/dio.dart';

import '../../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage secureStorage;
  Dio? _dio;

  AuthInterceptor({required this.secureStorage});

  void setDio(Dio dio) => _dio = dio;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final existingContentType = options.headers['Content-Type'];

    if (options.data is! FormData && existingContentType == null) {
      options.headers['Content-Type'] = 'application/json';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final bool isUnauthorized = err.response?.statusCode == 401;
    final String path = err.requestOptions.path;

    final bool isRefreshEndpoint =
        path.contains('/api/v1/auth/refresh') || path.contains('/auth/refresh');

    final bool isLoginEndpoint =
        path.contains('/api/v1/auth/login') || path.contains('/auth/login');

    if (isUnauthorized &&
        !isRefreshEndpoint &&
        !isLoginEndpoint &&
        _dio != null) {
      try {
        await _refreshToken();

        final Response<dynamic> retryResponse =
            await _dio!.fetch(err.requestOptions);
        return handler.resolve(retryResponse);
      } catch (_) {
        // Let the original error continue.
      }
    }

    handler.next(err);
  }

  Future<void> _refreshToken() async {
    await _dio!.post('/api/v1/auth/refresh');
  }
}
