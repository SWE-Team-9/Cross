import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Debug helper to simulate FCM notifications locally without Firebase access.
/// Use only in debug mode for testing notification handlers.
class FcmNotificationSimulator {
  /// Simulates a repost notification
  /// Example: "User reposted your track 'Song Title'"
  static RemoteMessage createRepostNotification({
    String? trackId,
    String? trackTitle,
    String? actorHandle,
    String? actorName,
    String? actorAvatarUrl,
  }) {
    return RemoteMessage(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      sentTime: DateTime.now(),
      from: 'firebase-adminsdk',
      notification: RemoteNotification(
        title: 'Track Reposted',
        body: '$actorName reposted your track "${trackTitle ?? "your track"}"',
      ),
      data: {
        'type': 'repost',
        'eventType': 'repost',
        'actorId': actorHandle ?? 'test-user-123',
        'actorHandle': actorHandle ?? 'testuser',
        'actorDisplayName': actorName ?? 'Test User',
        'actorAvatarUrl': actorAvatarUrl ?? '',
        'entityType': 'track',
        'entityId': trackId ?? 'track-123',
        'trackName': trackTitle ?? 'Test Track',
        'id': 'notif-${DateTime.now().millisecondsSinceEpoch}',
        'createdAt': DateTime.now().toIso8601String(),
        'isRead': 'false',
        'message': '$actorName reposted your track "${trackTitle ?? "your track"}"',
      },
    );
  }

  /// Simulates a like notification
  static RemoteMessage createLikeNotification({
    String? trackId,
    String? trackTitle,
    String? actorHandle,
    String? actorName,
    String? actorAvatarUrl,
  }) {
    return RemoteMessage(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      sentTime: DateTime.now(),
      from: 'firebase-adminsdk',
      notification: RemoteNotification(
        title: 'Track Liked',
        body: '$actorName liked your track "${trackTitle ?? "your track"}"',
      ),
      data: {
        'type': 'like',
        'eventType': 'like',
        'actorId': actorHandle ?? 'test-user-456',
        'actorHandle': actorHandle ?? 'testuser2',
        'actorDisplayName': actorName ?? 'Another User',
        'actorAvatarUrl': actorAvatarUrl ?? '',
        'entityType': 'track',
        'entityId': trackId ?? 'track-456',
        'trackName': trackTitle ?? 'Test Track',
        'id': 'notif-${DateTime.now().millisecondsSinceEpoch}',
        'createdAt': DateTime.now().toIso8601String(),
        'isRead': 'false',
        'message': '$actorName liked your track "${trackTitle ?? "your track"}"',
      },
    );
  }

  /// Simulates a follow notification
  static RemoteMessage createFollowNotification({
    String? actorHandle,
    String? actorName,
    String? actorAvatarUrl,
  }) {
    return RemoteMessage(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      sentTime: DateTime.now(),
      from: 'firebase-adminsdk',
      notification: RemoteNotification(
        title: 'New Follower',
        body: '$actorName followed you',
      ),
      data: {
        'type': 'follow',
        'eventType': 'follow',
        'actorId': actorHandle ?? 'test-follower',
        'actorHandle': actorHandle ?? 'newfollower',
        'actorDisplayName': actorName ?? 'New Follower',
        'actorAvatarUrl': actorAvatarUrl ?? '',
        'entityType': 'user',
        'entityId': actorHandle ?? 'test-follower',
        'trackName': '',
        'id': 'notif-${DateTime.now().millisecondsSinceEpoch}',
        'createdAt': DateTime.now().toIso8601String(),
        'isRead': 'false',
        'message': '$actorName followed you',
      },
    );
  }

  /// Logs notification details for debugging
  static void logNotification(RemoteMessage message) {
    debugPrint('╔════════════════════════════════════════════════');
    debugPrint('║ 🔔 SIMULATED FCM NOTIFICATION');
    debugPrint('╠════════════════════════════════════════════════');
    debugPrint('║ Message ID: ${message.messageId}');
    debugPrint('║ Type: ${message.data['type'] ?? 'unknown'}');
    debugPrint('║ Title: ${message.notification?.title}');
    debugPrint('║ Body: ${message.notification?.body}');
    debugPrint('║ ────────────────────────────────────────────────');
    debugPrint('║ Data:');
    message.data.forEach((key, value) {
      debugPrint('║   $key: $value');
    });
    debugPrint('╚════════════════════════════════════════════════');
  }
}
