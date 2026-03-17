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
  Future<bool> checkEmailExists({
    required String email,
  }) {
    return remoteDataSource.checkEmailExists(email: email);
  }

  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final response = await remoteDataSource.login(
      email: email,
      password: password,
    );

    await localDataSource.saveToken(response.token);
    return response.user.toEntity();
  }

  @override
  Future<User> register({
    required String email,
    required String password,
  }) async {
    final response = await remoteDataSource.register(
      email: email,
      password: password,
    );

    await localDataSource.saveToken(response.token);
    return response.user.toEntity();
  }

  @override
  Future<void> forgotPassword({
    required String email,
  }) {
    return remoteDataSource.forgotPassword(email: email);
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) {
    return remoteDataSource.resetPassword(
      email: email,
      code: code,
      newPassword: newPassword,
    );
  }

  @override
  Future<void> sendEmailVerification({
    required String email,
  }) {
    return remoteDataSource.sendEmailVerification(email: email);
  }

  @override
  Future<void> verifyEmail({
    required String email,
    required String code,
  }) {
    return remoteDataSource.verifyEmail(
      email: email,
      code: code,
    );
  }

  @override
  Future<User> completeProfile({
    required String displayName,
    required int birthMonth,
    required int birthDay,
    required int birthYear,
    required String gender,
  }) async {
    final token = await localDataSource.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No auth token found');
    }

    final userDto = await remoteDataSource.completeProfile(
      token: token,
      displayName: displayName,
      birthMonth: birthMonth,
      birthDay: birthDay,
      birthYear: birthYear,
      gender: gender,
    );

    return userDto.toEntity();
  }

  @override
  Future<User?> getCurrentUser() async {
    final token = await localDataSource.getToken();

    if (token == null || token.isEmpty) {
      return null;
    }

    final userDto = await remoteDataSource.getCurrentUser(token: token);
    return userDto.toEntity();
  }

  @override
  Future<void> logout() async {
    await localDataSource.clearToken();
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await localDataSource.getToken();
    return token != null && token.isNotEmpty;
  }
}
