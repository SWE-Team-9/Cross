import '../../domain/entities/notification_preferences_entity.dart';

class NotificationPreferencesModel extends NotificationPreferencesEntity {
  const NotificationPreferencesModel({
    required super.pushEnabled,
    required super.emailEnabled,
    required super.likesEnabled,
    required super.commentsEnabled,
    required super.followsEnabled,
    required super.repostsEnabled,
  });

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    final push = json['push'];
    final email = json['email'];
    return NotificationPreferencesModel(
      pushEnabled: (json['pushEnabled'] ?? push ?? true) == true,
      emailEnabled: (json['emailEnabled'] ?? email ?? false) == true,
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
      pushEnabled: entity.pushEnabled,
      emailEnabled: entity.emailEnabled,
      likesEnabled: entity.likesEnabled,
      commentsEnabled: entity.commentsEnabled,
      followsEnabled: entity.followsEnabled,
      repostsEnabled: entity.repostsEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushEnabled': pushEnabled,
      'emailEnabled': emailEnabled,
      'likesEnabled': likesEnabled,
      'commentsEnabled': commentsEnabled,
      'followsEnabled': followsEnabled,
      'repostsEnabled': repostsEnabled,
    };
  }
}
