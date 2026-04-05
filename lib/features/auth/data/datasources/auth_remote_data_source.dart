import 'dart:convert';

import '../../../../core/network/dio_client.dart';
import '../dto/auth_response_dto.dart';
import '../dto/user_dto.dart';
import '../../../../core/network/api_constants.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseDto> login({
    required String email,
    required String password,
    required bool rememberMe,
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

  Future<void> requestEmailChange({
    required String newEmail,
    required String currentPassword,
  });

  Future<void> confirmEmailChange({
    required String token,
  });

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
    required bool rememberMe,
    required String captchaToken,
  }) async {
    final response = await dioClient.dio.post(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
        'remember_me': rememberMe,
        'captcha_token': captchaToken,
      },
    );

    final responseData =
        response.data is String ? jsonDecode(response.data) : response.data;

    return AuthResponseDto(
      accessToken: '',
      refreshToken: '',
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
      ApiConstants.register,
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

    return AuthResponseDto(
      accessToken: '',
      refreshToken: '',
      user: UserDto.fromJson(responseData['user']),
    );
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await dioClient.dio.post(
      ApiConstants.forgotPassword,
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
      ApiConstants.resetPassword,
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
      ApiConstants.resendVerification,
      data: {'email': email},
    );
  }

  @override
  Future<void> verifyEmail({required String code}) async {
    await dioClient.dio.get(
      ApiConstants.verifyEmail,
      queryParameters: {'token': code},
    );
  }

  @override
  Future<void> requestEmailChange({
    required String newEmail,
    required String currentPassword,
  }) async {
    await dioClient.dio.post(
      ApiConstants.emailChange,
      data: {
        'new_email': newEmail,
        'current_password': currentPassword,
      },
    );
  }

  @override
  Future<void> confirmEmailChange({
    required String token,
  }) async {
    await dioClient.dio.post(
      ApiConstants.confirmEmailChange,
      data: {
        'token': token,
      },
    );
  }

  @override
  Future<UserDto> getCurrentUser() async {
    final response = await dioClient.dio.get(ApiConstants.currentUser);
    final responseData =
        response.data is String ? jsonDecode(response.data) : response.data;
    return UserDto.fromJson(responseData['user'] ?? responseData);
  }

  @override
  Future<void> logout() async {
    await dioClient.dio.post(ApiConstants.logout);
  }
}
