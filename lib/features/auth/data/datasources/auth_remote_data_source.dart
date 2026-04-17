import 'dart:convert';

//import 'package:dio/dio.dart';

import '../../../../core/network/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../dto/auth_response_dto.dart';
import '../dto/user_dto.dart';

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

  Uri buildGoogleAuthorizeUri({
    required String clientId,
    required String redirectUri,
    required String scope,
    required String state,
    required String codeChallenge,
  });

  Future<void> exchangeOAuthCodeForSession({
    required String clientId,
    required String code,
    required String redirectUri,
    required String codeVerifier,
  });
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
    print('API BASE URL => ${ApiConstants.baseUrl}');
    print('LOGIN URL => ${ApiConstants.baseUrl}${ApiConstants.login}');
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

  @override
  Uri buildGoogleAuthorizeUri({
    required String clientId,
    required String redirectUri,
    required String scope,
    required String state,
    required String codeChallenge,
  }) {
    final base =
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.oauthAuthorize}');
    return base.replace(
      queryParameters: {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': scope,
        'state': state,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
      },
    );
  }

  @override
  Future<void> exchangeOAuthCodeForSession({
    required String clientId,
    required String code,
    required String redirectUri,
    required String codeVerifier,
  }) async {
    print('🔥 POST ${ApiConstants.oauthToken}');
print('🔥 clientId = $clientId');
print('🔥 code = $code');
print('🔥 redirectUri = $redirectUri');
print('🔥 codeVerifier length = ${codeVerifier.length}');
    await dioClient.dio.post(
      ApiConstants.oauthToken,
      data: {
        'grant_type': 'authorization_code',
        'client_id': clientId,
        'code': code,
        'redirect_uri': redirectUri,
        'code_verifier': codeVerifier,
      },
      //options: Options(
        //contentType: Headers.formUrlEncodedContentType,
        //headers: const {
          //'Content-Type': Headers.formUrlEncodedContentType,
        //},
      //),
    );

    print('🔥 /oauth/token completed successfully');
  }
}
