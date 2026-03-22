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

    // حفظ التوكنز التي سحبناها من الـ Cookies
    await localDataSource.saveTokens(
      access: authResponse.accessToken,
      refresh: authResponse.refreshToken,
    );

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

    await localDataSource.saveTokens(
      access: authResponse.accessToken,
      refresh: authResponse.refreshToken,
    );

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
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
    } finally {
      await localDataSource.clearAll();
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await localDataSource.getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
