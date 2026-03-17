import 'user_dto.dart';

class AuthResponseDto {
  final String token;
  final UserDto user;

  const AuthResponseDto({
    required this.token,
    required this.user,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthResponseDto(
      token: json['token'] ?? '',
      user: UserDto.fromJson(json['user'] ?? {}),
    );
  }
}
