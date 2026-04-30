import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  final String id;
  final NotificationType type;
  final String message;
  final String actorId;
  final String actorDisplayName;
  final String actorHandle;
  final String actorAvatarUrl;
  final String entityType;
  final String entityId;
  final String trackName;
  final bool isRead;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.type,
    required this.message,
    required this.actorId,
    this.actorDisplayName = '',
    this.actorHandle = '',
    this.actorAvatarUrl = '',
    required this.entityType,
    required this.entityId,
    this.trackName = '',
    required this.isRead,
    required this.createdAt,
  });

  NotificationEntity copyWith({
    String? id,
    NotificationType? type,
    String? message,
    String? actorId,
    String? actorDisplayName,
    String? actorHandle,
    String? actorAvatarUrl,
    String? entityType,
    String? entityId,
    String? trackName,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      message: message ?? this.message,
      actorId: actorId ?? this.actorId,
      actorDisplayName: actorDisplayName ?? this.actorDisplayName,
      actorHandle: actorHandle ?? this.actorHandle,
      actorAvatarUrl: actorAvatarUrl ?? this.actorAvatarUrl,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      trackName: trackName ?? this.trackName,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        message,
        actorId,
        actorDisplayName,
        actorHandle,
        actorAvatarUrl,
        entityType,
        entityId,
        trackName,
        isRead,
        createdAt,
      ];
}

enum NotificationType {
  like,
  comment,
  follow,
  repost,
  unknown;

  static NotificationType fromString(String value) {
    final normalized = value.trim().toLowerCase();

    switch (normalized) {
      case 'like':
      case 'likes':
      case 'liked':
        return NotificationType.like;
      case 'comment':
      case 'comments':
      case 'commented':
        return NotificationType.comment;
      case 'follow':
      case 'follows':
      case 'followed':
        return NotificationType.follow;
      case 'repost':
      case 'reposts':
      case 'reposted':
        return NotificationType.repost;
      default:
        return NotificationType.unknown;
    }
  }
}