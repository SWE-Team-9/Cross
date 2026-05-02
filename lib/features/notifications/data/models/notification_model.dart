import '../../domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.type,
    required super.message,
    required super.actorId,
    required super.actorDisplayName,
    required super.actorHandle,
    required super.actorAvatarUrl,
    required super.entityType,
    required super.entityId,
    required super.trackName,
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
      actorMap['id'],
      actorMap['_id'],
      actorMap['handle'],
      actorMap['username'],
      actorMap['userName'],
      json['actorId'],
      json['actorHandle'],
      json['actorUsername'],
    ]);
    final actorDisplayName = _firstNonEmpty([
      actorMap['displayName'],
      actorMap['display_name'],
      actorMap['name'],
      actorMap['full_name'],
      actorMap['fullName'],
      json['actorDisplayName'],
      json['actorName'],
      json['senderName'],
      json['senderDisplayName'],
      json['authorName'],
    ]);
    final actorHandle = _firstNonEmpty([
      actorMap['handle'],
      actorMap['username'],
      actorMap['userName'],
      actorMap['user_handle'],
      json['actorHandle'],
      json['actorUsername'],
      json['senderHandle'],
      json['authorHandle'],
    ]);
    final actorAvatarUrl = _firstNonEmpty([
      actorMap['avatarUrl'],
      actorMap['avatar'],
      actorMap['profilePicture'],
      actorMap['imageUrl'],
      json['actorAvatarUrl'],
      json['actorAvatar'],
      json['avatarUrl'],
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

    final isUserEntity = entityType == 'user' ||
        NotificationType.fromString(typeRaw) == NotificationType.follow;

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
      type: notificationType,
      baseMessage: baseMessage,
      rootJson: json,
      targetMap: targetMap,
    );

    final message = _buildDisplayMessage(
      type: notificationType,
      baseMessage: baseMessage,
      actorLabel: _actorLabel(
        displayName: actorDisplayName,
        handle: actorHandle,
        fallbackId: actorId,
      ),
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
      actorDisplayName: actorDisplayName,
      actorHandle: actorHandle,
      actorAvatarUrl: actorAvatarUrl,
      entityType: entityType,
      entityId: entityId,
      trackName: trackName,
      isRead: isRead,
      createdAt: DateTime.tryParse(rawDate) ?? DateTime.now(),
    );
  }

  static String _buildDisplayMessage({
    required NotificationType type,
    required String baseMessage,
    required String actorLabel,
    required String trackName,
  }) {
    final normalizedMessage = baseMessage.trim();
    final normalizedActor = actorLabel.trim();
    final normalizedTrack = trackName.trim();

    if (type == NotificationType.like ||
        type == NotificationType.comment ||
        type == NotificationType.repost) {
      if (normalizedTrack.isNotEmpty) {
        return switch (type) {
          NotificationType.like =>
            '$normalizedActor liked your track $normalizedTrack',
          NotificationType.repost =>
            '$normalizedActor reposted your track $normalizedTrack',
          NotificationType.comment =>
            '$normalizedActor commented on your track $normalizedTrack',
          _ => normalizedMessage,
        };
      }
    }

    if (normalizedMessage.isEmpty) {
      if (normalizedTrack.isNotEmpty) {
        return switch (type) {
          NotificationType.like =>
            '$normalizedActor liked your track $normalizedTrack',
          NotificationType.repost =>
            '$normalizedActor reposted your track $normalizedTrack',
          NotificationType.comment =>
            '$normalizedActor commented on your track $normalizedTrack',
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

    return '$normalizedMessage $normalizedTrack';
  }

  static String _actorLabel({
    required String displayName,
    required String handle,
    required String fallbackId,
  }) {
    final byName = displayName.trim();
    if (byName.isNotEmpty) return byName;

    final byHandle = handle.trim();
    if (byHandle.isNotEmpty) {
      return byHandle.startsWith('@') ? byHandle.substring(1) : byHandle;
    }

    final byId = fallbackId.trim();
    if (byId.isNotEmpty) return byId;
    return 'Someone';
  }

  static String _extractTrackName({
    required NotificationType type,
    required String baseMessage,
    required Map<String, dynamic> rootJson,
    required Map<String, dynamic> targetMap,
  }) {
    final direct = _firstNonEmpty([
      targetMap['title'],
      targetMap['name'],
      targetMap['displayName'],
      targetMap['entityName'],
      targetMap['entityTitle'],
      targetMap['trackName'],
      targetMap['trackTitle'],
      rootJson['entityName'],
      rootJson['entityTitle'],
      rootJson['displayName'],
      rootJson['trackName'],
      rootJson['trackTitle'],
      rootJson['track_name'],
      rootJson['track_title'],
    ]);
    if (direct.isNotEmpty) return direct;

    String fromKnownMaps(dynamic node) {
      if (node is! Map) return '';
      final map = Map<String, dynamic>.from(node);
      return _firstNonEmpty([
        map['title'],
        map['name'],
        map['displayName'],
        map['entityName'],
        map['entityTitle'],
        map['trackName'],
        map['trackTitle'],
      ]);
    }

    final fromEntityMap = fromKnownMaps(rootJson['entity']);
    if (fromEntityMap.isNotEmpty) return fromEntityMap;

    final fromTargetMap = fromKnownMaps(rootJson['target']);
    if (fromTargetMap.isNotEmpty) return fromTargetMap;

    final fromTrackMap = fromKnownMaps(rootJson['track']);
    if (fromTrackMap.isNotEmpty) return fromTrackMap;

    final fromEntityIdMap = fromKnownMaps(rootJson['entityId']);
    if (fromEntityIdMap.isNotEmpty) return fromEntityIdMap;

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
            parentKey == 'entity' ||
            parentKey == 'target' ||
            parentKey == 'resource' ||
            parentKey == 'item' ||
            parentKey == 'subject' ||
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

    final deepResult = walk(rootJson);
    if (deepResult.isNotEmpty) return deepResult;

    if (type == NotificationType.like ||
        type == NotificationType.comment ||
        type == NotificationType.repost) {
      final fromMessage = _extractTrackFromMessage(baseMessage);
      if (fromMessage.isNotEmpty) return fromMessage;
    }

    return '';
  }

  static String _extractTrackFromMessage(String message) {
    final text = message.trim();
    if (text.isEmpty) return '';

    final quoted = RegExp(r'"([^"]+)"').firstMatch(text);
    if (quoted != null) {
      final value = quoted.group(1)?.trim() ?? '';
      if (value.isNotEmpty) return value;
    }

    final afterTrack =
        RegExp(r'\btrack\b\s+(.+)$', caseSensitive: false).firstMatch(text);
    if (afterTrack != null) {
      final value = afterTrack.group(1)?.trim() ?? '';
      if (value.isNotEmpty) return value;
    }

    return '';
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
      'actorDisplayName': actorDisplayName,
      'actorHandle': actorHandle,
      'actorAvatarUrl': actorAvatarUrl,
      'entityType': entityType,
      'entityId': entityId,
      'trackName': trackName,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
