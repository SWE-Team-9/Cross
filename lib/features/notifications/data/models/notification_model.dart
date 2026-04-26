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
    final notificationType = NotificationType.fromString(typeRaw);
    final baseMessage = (json['message'] ?? json['title'] ?? '').toString();

    final actor = json['actor'];
    final actorMap = actor is Map
        ? Map<String, dynamic>.from(actor)
        : const <String, dynamic>{};

    final actorId = _firstNonEmpty([
      actorMap['handle'],
      actorMap['username'],
      actorMap['userName'],
      actorMap['id'],
      actorMap['_id'],
      json['actorHandle'],
      json['actorUsername'],
      json['actorId'],
    ]);

    final target = json['target'] ?? json['entity'];
    final targetMap = target is Map
        ? Map<String, dynamic>.from(target)
        : const <String, dynamic>{};

    final entityType = _firstNonEmpty([
      json['entityType'],
      json['targetType'],
      targetMap['type'],
      targetMap['entityType'],
      targetMap['targetType'],
    ]).toLowerCase();

    final isUserEntity =
        entityType == 'user' || NotificationType.fromString(typeRaw) == NotificationType.follow;

    final entityId = _firstNonEmpty([
      if (isUserEntity) ...[
        targetMap['handle'],
        targetMap['username'],
        targetMap['userName'],
        json['entityHandle'],
      ],
      json['entityId'],
      json['targetId'],
      targetMap['trackId'],
      targetMap['id'],
      targetMap['_id'],
      targetMap['userId'],
      targetMap['profileId'],
      targetMap['commentId'],
      targetMap['targetId'],
    ]);

    final trackName = _extractTrackName(
      rootJson: json,
      targetMap: targetMap,
    );

    final message = _buildDisplayMessage(
      type: notificationType,
      baseMessage: baseMessage,
      trackName: trackName,
    );

    final isRead = (json['isRead'] ?? json['read'] ?? false) == true;

    final rawDate = (json['createdAt'] ??
            json['timestamp'] ??
            DateTime.now().toIso8601String())
        .toString();

    return NotificationModel(
      id: id,
      type: notificationType,
      message: message,
      actorId: actorId,
      entityType: entityType,
      entityId: entityId,
      isRead: isRead,
      createdAt: DateTime.tryParse(rawDate) ?? DateTime.now(),
    );
  }

  static String _buildDisplayMessage({
    required NotificationType type,
    required String baseMessage,
    required String trackName,
  }) {
    final normalizedMessage = baseMessage.trim();
    final normalizedTrack = trackName.trim();

    if (normalizedMessage.isEmpty) {
      if (normalizedTrack.isNotEmpty) {
        return switch (type) {
          NotificationType.like =>
            'Someone liked your track "$normalizedTrack"',
          NotificationType.repost =>
            'Someone reposted your track "$normalizedTrack"',
          NotificationType.comment =>
            'Someone commented on your track "$normalizedTrack"',
          _ => baseMessage,
        };
      }
      return baseMessage;
    }

    if (normalizedTrack.isEmpty ||
        (type != NotificationType.like &&
            type != NotificationType.repost &&
            type != NotificationType.comment)) {
      return normalizedMessage;
    }

    final alreadyContainsTitle =
        normalizedMessage.toLowerCase().contains(normalizedTrack.toLowerCase());
    if (alreadyContainsTitle) {
      return normalizedMessage;
    }

    return '$normalizedMessage "$normalizedTrack"';
  }

  static String _extractTrackName({
    required Map<String, dynamic> rootJson,
    required Map<String, dynamic> targetMap,
  }) {
    final direct = _firstNonEmpty([
      targetMap['title'],
      targetMap['name'],
      targetMap['trackName'],
      targetMap['trackTitle'],
      rootJson['trackName'],
      rootJson['trackTitle'],
      rootJson['track_name'],
      rootJson['track_title'],
    ]);
    if (direct.isNotEmpty) return direct;

    final visited = <Object>{};

    String walk(dynamic node, {String? parentKey}) {
      if (node == null) return '';
      if (node is Map) {
        if (visited.contains(node)) return '';
        visited.add(node);

        final map = Map<String, dynamic>.from(node);

        final isTrackContext = parentKey == 'track' ||
            parentKey == 'trackData' ||
            parentKey == 'track_data' ||
            map['type']?.toString().toLowerCase() == 'track' ||
            map['entityType']?.toString().toLowerCase() == 'track' ||
            map['targetType']?.toString().toLowerCase() == 'track';

        if (isTrackContext) {
          final inTrack = _firstNonEmpty([
            map['title'],
            map['name'],
            map['trackName'],
            map['trackTitle'],
          ]);
          if (inTrack.isNotEmpty) return inTrack;
        }

        for (final entry in map.entries) {
          final found = walk(entry.value, parentKey: entry.key);
          if (found.isNotEmpty) return found;
        }
      } else if (node is List) {
        for (final item in node) {
          final found = walk(item, parentKey: parentKey);
          if (found.isNotEmpty) return found;
        }
      }

      return '';
    }

    return walk(rootJson);
  }

  static String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
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
