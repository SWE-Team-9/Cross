import '../../domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.type,
    required super.message,
    required super.actorId,
    required super.entityType,
    required super.entityId,
    required super.isRead,
    required super.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['_id'] ?? '').toString();
    final typeRaw = (json['type'] ?? json['eventType'] ?? '').toString();
    final message = (json['message'] ?? json['title'] ?? '').toString();

    final actor = json['actor'];
    final actorId = actor is Map<String, dynamic>
        ? (actor['id'] ?? actor['_id'] ?? '').toString()
        : (json['actorId'] ?? '').toString();

    final entityType =
        (json['entityType'] ?? json['targetType'] ?? '').toString();
    final entityId = (json['entityId'] ?? json['targetId'] ?? '').toString();
    final isRead = (json['isRead'] ?? json['read'] ?? false) == true;

    final rawDate = (json['createdAt'] ??
            json['timestamp'] ??
            DateTime.now().toIso8601String())
        .toString();

    return NotificationModel(
      id: id,
      type: NotificationType.fromString(typeRaw),
      message: message,
      actorId: actorId,
      entityType: entityType,
      entityId: entityId,
      isRead: isRead,
      createdAt: DateTime.tryParse(rawDate) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'message': message,
      'actorId': actorId,
      'entityType': entityType,
      'entityId': entityId,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
