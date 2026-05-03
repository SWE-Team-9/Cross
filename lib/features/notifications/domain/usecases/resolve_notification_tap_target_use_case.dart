import 'package:soundcloud_clone/features/messaging/domain/usecases/get_or_create_direct_conversation_usecase.dart';

import '../entities/notification_entity.dart';
import '../entities/notification_tap_target.dart';

class ResolveNotificationTapTargetUseCase {
  ResolveNotificationTapTargetUseCase(
    this._getOrCreateDirectConversationUseCase,
  );

  final GetOrCreateDirectConversationUseCase
      _getOrCreateDirectConversationUseCase;

  Future<NotificationTapTarget?> call(NotificationEntity notification) async {
    switch (notification.type) {
      case NotificationType.comment:
        final trackId = notification.entityId.trim();
        if (trackId.isEmpty) return null;
        return NotificationCommentsTapTarget(trackId: trackId);
      case NotificationType.message:
        final receiverId = _firstNonEmpty([
          notification.actorId,
          notification.entityId,
          notification.actorHandle,
        ]);

        if (receiverId.isEmpty) return null;

        try {
          final conversation = await _getOrCreateDirectConversationUseCase(
            receiverId: receiverId,
          );
          return NotificationConversationTapTarget(conversation: conversation);
        } catch (_) {
          return null;
        }
      case NotificationType.like:
      case NotificationType.follow:
      case NotificationType.repost:
        final handle = _sanitizeHandle(
          _firstNonEmpty([
            notification.actorHandle,
            notification.entityId,
            notification.actorId,
          ]),
        );

        if (handle.isEmpty) return null;
        return NotificationProfileTapTarget(handle: handle);
      case NotificationType.unknown:
        return null;
    }
  }

  static String _firstNonEmpty(Iterable<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  static String _sanitizeHandle(String raw) {
    var candidate = raw.trim();
    if (candidate.startsWith('@')) {
      candidate = candidate.substring(1);
    }

    final match = RegExp(r'^[A-Za-z0-9._-]+').firstMatch(candidate);
    return match?.group(0) ?? '';
  }
}
