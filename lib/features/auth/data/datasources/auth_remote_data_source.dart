import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../dto/auth_response_dto.dart';
import '../dto/check_email_response_dto.dart';
import '../dto/user_dto.dart';
import 'dart:convert';

abstract class AuthRemoteDataSource {
  Future<bool> checkEmailExists({
    required String email,
  });

  Future<AuthResponseDto> login({
    required String email,
    required String password,
  });

  Future<AuthResponseDto> register({
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

  Future<UserDto> completeProfile({
    required String token,
    required String displayName,
    required int birthMonth,
    required int birthDay,
    required int birthYear,
    required String gender,
  });

  Future<UserDto> getCurrentUser({
    required String token,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;

  AuthRemoteDataSourceImpl(this.dioClient);

  @override
  Future<bool> checkEmailExists({
    required String email,
  }) async {
    final response = await dioClient.dio.post(
      '/auth/check-email',
      data: {
        'email': email,
      },
    );

    //final dto = CheckEmailResponseDto.fromJson(response.data);
    //return dto.exists;

    final responseData = response.data is String 
        ? jsonDecode(response.data) 
        : response.data;

    final dto = CheckEmailResponseDto.fromJson(responseData);
    return dto.exists;
  }

  @override
  Future<AuthResponseDto> login({
    required String email,
    required String password,
  }) async {
    final response = await dioClient.dio.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );
     final responseData = response.data is String 
        ? jsonDecode(response.data) 
        : response.data;

    return AuthResponseDto.fromJson(responseData);
   
  }

  @override
  Future<AuthResponseDto> register({
    required String email,
    required String password,
  }) async {
    final response = await dioClient.dio.post(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
      },
    );

    final responseData = response.data is String 
        ? jsonDecode(response.data) 
        : response.data;

    return AuthResponseDto.fromJson(responseData);
  }

  @override
  Future<void> forgotPassword({
    required String email,
  }) async {
    await dioClient.dio.post(
      '/auth/forgot-password',
      data: {
        'email': email,
      },
    );
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await dioClient.dio.post(
      '/auth/reset-password',
      data: {
        'email': email,
        'code': code,
        'new_password': newPassword,
      },
    );
  }

  @override
  Future<void> sendEmailVerification({
    required String email,
  }) async {
    await dioClient.dio.post(
      '/auth/send-verification-email',
      data: {
        'email': email,
      },
    );
  }

  @override
  Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    await dioClient.dio.post(
      '/auth/verify-email',
      data: {
        'email': email,
        'code': code,
      },
    );
  }

  @override
  Future<UserDto> completeProfile({
    required String token,
    required String displayName,
    required int birthMonth,
    required int birthDay,
    required int birthYear,
    required String gender,
  }) async {
    final response = await dioClient.dio.post(
      '/auth/complete-profile',
      data: {
        'display_name': displayName,
        'birth_month': birthMonth,
        'birth_day': birthDay,
        'birth_year': birthYear,
        'gender': gender,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );
final responseData = response.data is String 
        ? jsonDecode(response.data) 
        : response.data;

 
    return UserDto.fromJson(responseData);
  }

  @override
  Future<UserDto> getCurrentUser({
    required String token,
  }) async {
    final response = await dioClient.dio.get(
      '/auth/me',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    return UserDto.fromJson(response.data);
  }
}