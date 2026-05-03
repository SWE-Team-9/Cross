import '../../domain/entities/notification_preferences_entity.dart';

class NotificationPreferencesModel extends NotificationPreferencesEntity {
  const NotificationPreferencesModel({
    required super.likesEnabled,
    required super.commentsEnabled,
    required super.followsEnabled,
    required super.repostsEnabled,
  });

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    /// Parse preferences with fallback to defaults (true)
    /// API may return either camelCase (likesEnabled) or snake_case (likes)
    bool _parsePreference(String camelKey, String snakeKey) {
      final value = json[camelKey] ?? json[snakeKey];
      if (value is bool) return value;
      if (value is int) return value > 0;
      return true; // Default to enabled
    }

    return NotificationPreferencesModel(
      likesEnabled: _parsePreference('likesEnabled', 'likes'),
      commentsEnabled: _parsePreference('commentsEnabled', 'comments'),
      followsEnabled: _parsePreference('followsEnabled', 'follows'),
      repostsEnabled: _parsePreference('repostsEnabled', 'reposts'),
    );
  }

  factory NotificationPreferencesModel.fromEntity(
    NotificationPreferencesEntity entity,
  ) {
    return NotificationPreferencesModel(
      likesEnabled: entity.likesEnabled,
      commentsEnabled: entity.commentsEnabled,
      followsEnabled: entity.followsEnabled,
      repostsEnabled: entity.repostsEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'likes': likesEnabled,
      'comments': commentsEnabled,
      'follows': followsEnabled,
      'reposts': repostsEnabled,
    };
  }
}
