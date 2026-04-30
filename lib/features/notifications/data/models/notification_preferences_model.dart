import '../../domain/entities/notification_preferences_entity.dart';

class NotificationPreferencesModel extends NotificationPreferencesEntity {
  const NotificationPreferencesModel({
    required super.likesEnabled,
    required super.commentsEnabled,
    required super.followsEnabled,
    required super.repostsEnabled,
  });

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesModel(
      likesEnabled: (json['likesEnabled'] ?? json['likes'] ?? true) == true,
      commentsEnabled:
          (json['commentsEnabled'] ?? json['comments'] ?? true) == true,
      followsEnabled:
          (json['followsEnabled'] ?? json['follows'] ?? true) == true,
      repostsEnabled:
          (json['repostsEnabled'] ?? json['reposts'] ?? true) == true,
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
