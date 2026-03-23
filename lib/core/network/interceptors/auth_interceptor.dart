import 'package:dio/dio.dart';

import '../../storage/secure_storage.dart';

/// Handles automatic token refresh when the access token expires.
///
/// The access_token and refresh_token are httpOnly cookies managed
/// automatically by CookieManager in DioClient.
/// This interceptor's only job is to call the refresh endpoint on 401
/// so the user is never unexpectedly logged out mid-session.
class AuthInterceptor extends Interceptor {
  final SecureStorage secureStorage;
  Dio? _dio;

  AuthInterceptor({required this.secureStorage});

  /// Called by DioClient after construction so we have access to the Dio instance
  void setDio(Dio dio) => _dio = dio;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    // CookieManager handles cookie attachment automatically.
    if (options.data is! FormData) {
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
    final bool isRefreshEndpoint =
        err.requestOptions.path.contains('/auth/refresh');
    final bool isLoginEndpoint =
        err.requestOptions.path.contains('/auth/login');

    if (isUnauthorized && !isRefreshEndpoint && !isLoginEndpoint && _dio != null) {
      try {
        await _refreshToken();

        final Response<dynamic> retryResponse =
            await _dio!.fetch(err.requestOptions);
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