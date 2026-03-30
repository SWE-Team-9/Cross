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
    required bool rememberMe,
    required String captchaToken,
  }) async {
    final authResponse = await remoteDataSource.login(
      email: email,
      password: password,
      rememberMe: rememberMe,
      captchaToken: captchaToken,
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
  Future<void> requestEmailChange({
    required String newEmail,
    required String currentPassword,
  }) {
    return remoteDataSource.requestEmailChange(
      newEmail: newEmail,
      currentPassword: currentPassword,
    );
  }

  @override
  Future<void> confirmEmailChange({
    required String token,
  }) {
    return remoteDataSource.confirmEmailChange(token: token);
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
    } finally {
      await localDataSource.clearAll();
    }
  }
}