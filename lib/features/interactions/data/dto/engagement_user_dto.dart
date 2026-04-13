import '../../domain/entities/engagement_user.dart';

class EngagementUserDto {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final DateTime? interactedAt;

  const EngagementUserDto({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.interactedAt,
  });

  factory EngagementUserDto.fromJson(Map<String, dynamic> json) {
    final user = Map<String, dynamic>.from(
      (json['user'] as Map?) ?? const {},
    );

    return EngagementUserDto(
      userId: (user['userId'] ?? user['id'] ?? '').toString(),
      displayName:
          (user['displayName'] ?? user['display_name'] ?? 'Unknown User')
              .toString(),
      avatarUrl:
          user['avatarUrl']?.toString() ?? user['avatar_url']?.toString(),
      interactedAt: _parseDate(json['interactedAt'] ?? json['interacted_at']),
    );
  }

  EngagementUser toEntity() {
    return EngagementUser(
      userId: userId,
      displayName: displayName,
      avatarUrl: avatarUrl,
      interactedAt: interactedAt,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
