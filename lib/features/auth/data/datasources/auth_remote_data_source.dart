import 'package:dio/dio.dart';
import 'dart:convert';

import '../../../../core/network/dio_client.dart';
import '../dto/user_dto.dart';

abstract class AuthRemoteDataSource {
  Future<UserDto> login({
    required String email,
    required String password,
    required String captchaToken,
  });

  Future<UserDto> register({
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
    required String code,
  });

  Future<UserDto> getCurrentUser();

  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;

  AuthRemoteDataSourceImpl(this.dioClient);

  @override
  Future<UserDto> login({
    required String email,
    required String password,
    required String captchaToken,
  }) async {
    final response = await dioClient.dio.post('/api/v1/auth/login',
        data: {
          'email': email,
          'password': password,
          //'captcha_token': captchaToken,
          "remember_me": true,
        },
        options: Options(headers: {
         
        }));

    final responseData =
        response.data is String ? jsonDecode(response.data) : response.data;

    return UserDto.fromJson(responseData['user']);
  }

  @override
  Future<UserDto> register({
    required String email,
    required String password,
    required String passwordConfirm,
    required String displayName,
    required String dateOfBirth,
    required String gender,
    required String captchaToken,
  }) async {
    final response = await dioClient.dio.post('http://13.53.103.19:3001/api/v1/auth/register',
        data: {
          'email': email,
          'password': password,
          'password_confirm': passwordConfirm,
          'display_name': displayName,
          'date_of_birth': dateOfBirth,
          'gender': gender,
          'captcha_token': captchaToken,
        },
        options: Options(headers: {
          
        }));

    final responseData =
        response.data is String ? jsonDecode(response.data) : response.data;
    return UserDto.fromJson(responseData['user']);
  }

  @override
  Future<void> forgotPassword({
    required String email,
  }) async {
    await dioClient.dio.post(
      '/api/v1/auth/forgot-password',
      data: {
        'email': email,
      },
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
  Future<void> sendEmailVerification({
    required String email,
  }) async {
    await dioClient.dio.post(
      '/api/v1/auth/resend-verification',
      data: {
        'email': email,
      },
    );
  }

  @override
  Future<void> verifyEmail({
    required String code,
  }) async {
    await dioClient.dio.get(
      '/api/v1/auth/verify-email',
      queryParameters: {
        'token': code,
      },
    );
  }

  @override
  Future<UserDto> getCurrentUser() async {
    final response = await dioClient.dio.get('/api/v1/auth/me');
    final responseData =
        response.data is String ? jsonDecode(response.data) : response.data;
    return UserDto.fromJson(responseData);
  }

  @override
  Future<void> logout() async {
    await dioClient.dio.post('/api/v1/auth/logout');
  }
}
