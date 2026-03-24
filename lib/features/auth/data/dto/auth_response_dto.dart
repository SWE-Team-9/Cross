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
    // ملاحظة: بناءً على صورتك، التوكنز موجودة في الـ Cookie
    // إذا كان الـ API يرجعها أيضاً في الـ Body (الـ JSON)، فسيتم قراءتها من هنا.
    // إذا كانت في الكوكيز فقط، الـ DioClient سيتولى أمرها تلقائياً.
    return AuthResponseDto(
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      user: UserDto.fromJson(json['user'] ?? {}),
    );
  }
}
