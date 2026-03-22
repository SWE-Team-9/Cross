// Dart SDK
import 'dart:convert';
 
// Flutter
// Third-party
// Project
import '../../../../core/network/dio_client.dart';
import '../dto/auth_response_dto.dart';
import '../dto/user_dto.dart';
 
abstract class AuthRemoteDataSource {
  Future<AuthResponseDto> login({
    required String email,
    required String password,
    required String captchaToken,
  });
 
  Future<AuthResponseDto> register({
    required String email,
    required String password,
    required String passwordConfirm,
    required String displayName,
    required String dateOfBirth,
    required String gender,
    required String captchaToken,
  });
 
  Future<void> forgotPassword({required String email});
  Future<void> resetPassword({
    required String code,
    required String newPassword,
    required String newPasswordConfirm,
  });
  Future<void> sendEmailVerification({required String email});
  Future<void> verifyEmail({required String code});
  Future<UserDto> getCurrentUser();
  Future<void> logout();
}
 
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;
 
  AuthRemoteDataSourceImpl(this.dioClient);
 
  @override
  Future<AuthResponseDto> login({
    required String email,
    required String password,
    required String captchaToken,
  }) async {
    final response = await dioClient.dio.post(
      '/api/v1/auth/login',
      data: {
        'email': email,
        'password': password,
        'remember_me': true,
      },
    );
 
    final responseData =
        response.data is String ? jsonDecode(response.data) : response.data;
 
    // CookieManager automatically stores the httpOnly access_token and
    // refresh_token cookies from the Set-Cookie header.
    // We must NOT extract them manually here — doing so would save them
    // to SecureStorage, which causes AuthInterceptor to add them as a
    // Bearer header on every subsequent request, resulting in double auth.
    return AuthResponseDto(
      accessToken: '',   // intentionally empty — managed by CookieManager
      refreshToken: '',  // intentionally empty — managed by CookieManager
      user: UserDto.fromJson(responseData['user']),
    );
  }
 
  @override
  Future<AuthResponseDto> register({
    required String email,
    required String password,
    required String passwordConfirm,
    required String displayName,
    required String dateOfBirth,
    required String gender,
    required String captchaToken,
  }) async {
    final response = await dioClient.dio.post(
      '/api/v1/auth/register',
      data: {
        'email': email,
        'password': password,
        'password_confirm': passwordConfirm,
        'display_name': displayName,
        'date_of_birth': dateOfBirth,
        'gender': gender,
        'captcha_token': captchaToken,
      },
    );
 
    final responseData =
        response.data is String ? jsonDecode(response.data) : response.data;
 
    // Same as login — no manual cookie extraction.
    return AuthResponseDto(
      accessToken: '',
      refreshToken: '',
      user: UserDto.fromJson(responseData['user']),
    );
  }
 
  @override
  Future<void> forgotPassword({required String email}) async {
    await dioClient.dio.post(
      '/api/v1/auth/forgot-password',
      data: {'email': email},
    );
  }
 
  @override
  Future<void> resetPassword({
    required String code,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    await dioClient.dio.post(
      '/api/v1/auth/reset-password',
      data: {
        'token': code,
        'new_password': newPassword,
        'new_password_confirm': newPasswordConfirm,
      },
    );
  }
 
  @override
  Future<void> sendEmailVerification({required String email}) async {
    await dioClient.dio.post(
      '/api/v1/auth/resend-verification',
      data: {'email': email},
    );
  }
 
  @override
  Future<void> verifyEmail({required String code}) async {
    await dioClient.dio.get(
      '/api/v1/auth/verify-email',
      queryParameters: {'token': code},
    );
  }
 
  @override
  Future<UserDto> getCurrentUser() async {
    final response = await dioClient.dio.get('/api/v1/auth/me');
    final responseData =
        response.data is String ? jsonDecode(response.data) : response.data;
    return UserDto.fromJson(responseData['user'] ?? responseData);
  }
 
  @override
  Future<void> logout() async {
    await dioClient.dio.post('/api/v1/auth/logout');
  }
}
 