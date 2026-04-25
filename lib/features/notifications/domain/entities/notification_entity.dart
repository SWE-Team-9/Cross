import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  final String id;
  final NotificationType type;
  final String message;
  final String actorId;
  final String entityType;
  final String entityId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.type,
    required this.message,
    required this.actorId,
    required this.entityType,
    required this.entityId,
    required this.isRead,
    required this.createdAt,
  });

  NotificationEntity copyWith({
    String? id,
    NotificationType? type,
    String? message,
    String? actorId,
    String? entityType,
    String? entityId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      message: message ?? this.message,
      actorId: actorId ?? this.actorId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
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
        entityType,
        entityId,
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
    return NotificationType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => NotificationType.unknown,
    );
  }
}