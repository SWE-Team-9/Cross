// Dart SDK
// Flutter
// Third-party
// Project
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<User> login({
    required String email,
    required String password,
    required String captchaToken,
  }) async {
    final authResponse = await remoteDataSource.login(
      email: email,
      password: password,
      captchaToken: captchaToken,
    );

    // Tokens are managed by CookieManager as httpOnly cookies.
    // Saving them to SecureStorage is what caused the double auth bug —
    // the stored token was being read by something and added as a Bearer
    // header on every request while CookieManager was also sending the cookie.
    // Solution: do not save tokens here at all.

    return authResponse.user.toEntity();
  }

  @override
  Future<User> register({
    required String email,
    required String password,
    required String passwordConfirm,
    required String displayName,
    required String dateOfBirth,
    required String gender,
    required String captchaToken,
  }) async {
    final authResponse = await remoteDataSource.register(
      email: email,
      password: password,
      passwordConfirm: passwordConfirm,
      displayName: displayName,
      dateOfBirth: dateOfBirth,
      gender: gender,
      captchaToken: captchaToken,
    );

    // Same reason as login — no token saving.
    return authResponse.user.toEntity();
  }

  @override
  Future<void> forgotPassword({required String email}) {
    return remoteDataSource.forgotPassword(email: email);
  }

  @override
  Future<void> resetPassword({
    required String code,
    required String newPassword,
    required String newPasswordConfirm,
  }) {
    return remoteDataSource.resetPassword(
      code: code,
      newPassword: newPassword,
      newPasswordConfirm: newPasswordConfirm,
    );
  }

  @override
  Future<void> sendEmailVerification({required String email}) {
    return remoteDataSource.sendEmailVerification(email: email);
  }

  @override
  Future<void> verifyEmail({required String email, required String code}) {
    return remoteDataSource.verifyEmail(code: code);
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final userDto = await remoteDataSource.getCurrentUser();
      return userDto.toEntity();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    // CHANGED: was reading token from SecureStorage:
    //   final token = await localDataSource.getAccessToken();
    //   return token != null && token.isNotEmpty;
    //
    // Problem with the old approach:
    // 1. A saved token could be expired — user would appear logged in but all
    //    requests would fail with 401
    // 2. Reading from SecureStorage is what triggered AuthInterceptor to add
    //    the Bearer header, causing the double auth bug
    //
    // New approach: call GET /auth/me directly.
    // If the httpOnly cookie is valid → server returns 200 → user is logged in
    // If the cookie is expired/missing → server returns 401 → not logged in
    // This is always accurate and removes the need for SecureStorage entirely.
    try {
      await remoteDataSource.getCurrentUser();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
    } catch (_) {
      // Remote logout failure is non-fatal.
      // The user is logged out locally regardless —
      // cookies will expire on the server eventually.
    } finally {
      await localDataSource.clearAll();
    }
  }
}
