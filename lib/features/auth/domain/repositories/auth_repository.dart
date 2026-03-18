import '../entities/user.dart';

abstract class AuthRepository {
  Future<bool> checkEmailExists({
    required String email,
  });

  Future<User> login({
    required String email,
    required String password,
  });

  Future<User> register({
    required String email,
    required String password,
  });

  Future<void> forgotPassword({
    required String email,
  });

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  Future<void> sendEmailVerification({
    required String email,
  });

  Future<void> verifyEmail({
    required String email,
    required String code,
  });

  Future<User> completeProfile({
    required String displayName,
    required int birthMonth,
    required int birthDay,
    required int birthYear,
    required String gender,
  });

  Future<User?> getCurrentUser();

  Future<void> logout();

  Future<bool> isLoggedIn();
}
