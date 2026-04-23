import '../../domain/entities/participant_entity.dart';

class ParticipantDto {
  final String id;
  final String displayName;
  final String handle;
  final String? avatarUrl;

  const ParticipantDto({
    required this.id,
    required this.displayName,
    required this.handle,
    required this.avatarUrl,
  });

  factory ParticipantDto.fromJson(Map<String, dynamic> json) {
    return ParticipantDto(
      id: (json['id'] ?? json['_id'] ?? json['userId'] ?? json['user_id'] ?? '')
          .toString(),
      displayName: (json['display_name'] ??
              json['displayName'] ??
              json['name'] ??
              json['username'] ??
              '')
          .toString(),
      handle: (json['handle'] ?? json['username'] ?? '').toString(),
      avatarUrl: (json['avatar_url'] ??
              json['avatarUrl'] ??
              json['profileImageUrl'] ??
              json['profile_image_url'])
          ?.toString(),
    );
  }

  ParticipantEntity toEntity() {
    return ParticipantEntity(
      id: id,
      displayName: displayName,
      handle: handle,
      avatarUrl: avatarUrl,
    );
  }
}