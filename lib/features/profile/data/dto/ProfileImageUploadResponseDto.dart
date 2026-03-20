import '../../domain/entities/ProfileImageUploadResult.dart';

class ProfileImageUploadResponseDto {
  const ProfileImageUploadResponseDto({
    required this.url,
    required this.key,
  });

  final String url;
  final String key;

  factory ProfileImageUploadResponseDto.fromJson(Map<String, dynamic> json) {
    return ProfileImageUploadResponseDto(
      url: json['url'] as String? ?? '',
      key: json['key'] as String? ?? '',
    );
  }

  ProfileImageUploadResult toEntity(ProfileImageType type) {
    return ProfileImageUploadResult(
      type: type,
      url: url,
      key: key,
    );
  }
}
