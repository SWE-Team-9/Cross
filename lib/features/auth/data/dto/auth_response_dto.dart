import 'user_dto.dart';

class AuthResponseDto {
  final String accessToken;
  final String refreshToken;
  final UserDto user;

  const AuthResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {

    return AuthResponseDto(
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      user: UserDto.fromJson(json['user'] ?? {}),
    );
  }
}
