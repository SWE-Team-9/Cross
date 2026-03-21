
import 'dart:convert';
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
        "remember_me": true,
      },
    );

    final responseData = response.data is String ? jsonDecode(response.data) : response.data;

    // استخراج التوكنز من الـ Cookies الموجودة في الـ Headers
    String accessToken = '';
    String refreshToken = '';

    final cookies = response.headers['set-cookie'];
    if (cookies != null) {
      for (var cookie in cookies) {
        if (cookie.contains('access_token=')) {
          accessToken = cookie.split('access_token=')[1].split(';')[0];
        }
        if (cookie.contains('refresh_token=')) {
          refreshToken = cookie.split('refresh_token=')[1].split(';')[0];
        }
      }
    }

    return AuthResponseDto(
      accessToken: accessToken,
      refreshToken: refreshToken,
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

    final responseData = response.data is String ? jsonDecode(response.data) : response.data;

    String accessToken = '';
    String refreshToken = '';

    final cookies = response.headers['set-cookie'];
    if (cookies != null) {
      for (var cookie in cookies) {
        if (cookie.contains('access_token=')) {
          accessToken = cookie.split('access_token=')[1].split(';')[0];
        }
        if (cookie.contains('refresh_token=')) {
          refreshToken = cookie.split('refresh_token=')[1].split(';')[0];
        }
      }
    }

    return AuthResponseDto(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: UserDto.fromJson(responseData['user']),
    );
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await dioClient.dio.post('/api/v1/auth/forgot-password', data: {'email': email});
  }

  @override
  Future<void> resetPassword({
    required String code,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    await dioClient.dio.post('/api/v1/auth/reset-password', data: {
      'token': code,
      'new_password': newPassword,
      'new_password_confirm': newPasswordConfirm,
    });
  }

  @override
  Future<void> sendEmailVerification({required String email}) async {
    await dioClient.dio.post('/api/v1/auth/resend-verification', data: {'email': email});
  }

  @override
  Future<void> verifyEmail({required String code}) async {
    await dioClient.dio.get('/api/v1/auth/verify-email', queryParameters: {'token': code});
  }

  @override
  Future<UserDto> getCurrentUser() async {
    final response = await dioClient.dio.get('/api/v1/auth/me');
    final responseData = response.data is String ? jsonDecode(response.data) : response.data;
    return UserDto.fromJson(responseData['user'] ?? responseData);
  }

  @override
  Future<void> logout() async {
    await dioClient.dio.post('/api/v1/auth/logout');
  }
}