// Dart SDK
// Flutter
// Third-party
import 'package:dio/dio.dart';

// Project
import '../../storage/secure_storage.dart';

/// Handles automatic token refresh when the access token expires.
///
/// The access_token and refresh_token are httpOnly cookies managed
/// automatically by CookieManager in DioClient.
/// This interceptor's only job is to call the refresh endpoint on 401
/// so the user is never unexpectedly logged out mid-session.
class AuthInterceptor extends Interceptor {
  final SecureStorage secureStorage;
  // Keep a reference to Dio so we can retry the failed request
  // after a successful token refresh
  Dio? _dio;

  AuthInterceptor({required this.secureStorage});

  /// Called by DioClient after construction so we have access to the Dio instance
  void setDio(Dio dio) => _dio = dio;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    // Nothing to add manually — CookieManager handles cookie attachment
    // The only thing we do here is ensure JSON content type is set
    // for non-multipart requests
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
    final isUnauthorized = err.response?.statusCode == 401;
    final isRefreshEndpoint = err.requestOptions.path.contains('/auth/refresh');
    final isLoginEndpoint = err.requestOptions.path.contains('/auth/login');

    // Only attempt refresh if:
    // 1. The error is a 401 (token expired)
    // 2. The failing request was NOT the refresh endpoint itself
    //    (avoids infinite refresh loop)
    // 3. The failing request was NOT login
    //    (if login fails with 401, it's wrong credentials — not expired token)
    if (isUnauthorized && !isRefreshEndpoint && !isLoginEndpoint) {
      try {
        await _refreshToken();

        // Retry the original request — CookieManager will now attach
        // the new access_token cookie automatically
        final retryResponse = await _dio!.fetch(err.requestOptions);
        return handler.resolve(retryResponse);
      } catch (_) {
        // Refresh failed — user must log in again
        // TODO: call getIt<AuthCubit>().logout() here in Sprint 2 integration
      }
    }

    handler.next(err);
  }

  Future<void> _refreshToken() async {
    // POST /api/v1/auth/refresh
    // No body needed — refresh_token cookie is sent automatically
    // by CookieManager. Server rotates both cookies on success.
    await _dio!.post('/auth/refresh');
  }
}
