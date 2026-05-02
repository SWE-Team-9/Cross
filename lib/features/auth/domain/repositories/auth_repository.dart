import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login({
    required String email,
    required String password,
    required bool rememberMe,
    required String captchaToken,
  });

  Future<User> register({
    required String email,
    required String password,
    required String passwordConfirm,
    required String displayName,
    required String dateOfBirth,
    required String gender,
    required String captchaToken,
  });

  Future<void> forgotPassword({
    required String email,
  });

  Future<void> resetPassword({
    required String code,
    required String newPassword,
    required String newPasswordConfirm,
  });

  Future<void> sendEmailVerification({
    required String email,
  });

  Future<void> verifyEmail({
    required String email,
    required String code,
  });

  Future<void> requestEmailChange({
    required String newEmail,
    required String currentPassword,
  });

  Future<void> confirmEmailChange({
    required String token,
  });

  Future<User?> getCurrentUser();

  Future<void> logout();

  Future<bool> isLoggedIn();

  Uri buildGoogleAuthorizeUri({
    required String state,
    required String codeChallenge,
    required String redirectUri,
  });

  Future<void> exchangeOAuthCodeForSession({
    required String code,
    required String redirectUri,
    required String codeVerifier,
  });
}
