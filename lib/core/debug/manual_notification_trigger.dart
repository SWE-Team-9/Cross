import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../../features/notifications/data/models/notification_model.dart';
import '../../features/notifications/domain/entities/notification_entity.dart';
import '../../features/notifications/presentation/bloc/notifications_bloc.dart';

/// Debug service to manually trigger notifications in-app without Firebase.
/// Only available in debug mode.
class ManualNotificationTrigger {
  static final GetIt _getIt = GetIt.instance;

  /// Create a notification model with validated parameters
  static NotificationModel _createNotification({
    required String id,
    required NotificationType type,
    required String message,
    required String actorId,
    required String actorDisplayName,
    required String actorHandle,
    required String actorAvatarUrl,
    required String entityType,
    required String entityId,
    required String trackName,
  }) {
    return NotificationModel(
      id: id,
      type: type,
      message: message,
      actorId: actorId,
      actorDisplayName: actorDisplayName,
      actorHandle: actorHandle,
      actorAvatarUrl: actorAvatarUrl,
      entityType: entityType,
      entityId: entityId,
      trackName: trackName,
      isRead: false,
      createdAt: DateTime.now(),
    );
  }

  /// Emit notification to the BLoC
  static void _emitNotificationToBloc(NotificationEntity notification) {
    if (!kDebugMode) return;

    try {
      if (!_getIt.isRegistered<NotificationsBloc>()) {
        debugPrint('⚠️ NotificationsBloc not registered');
        return;
      }

      final bloc = _getIt<NotificationsBloc>();
      bloc.add(RealtimeNotificationReceived(notification));
      debugPrint('📬 [${notification.type}] ${notification.message}');
    } catch (e) {
      debugPrint('❌ Error emitting notification: $e');
    }
  }

  /// Trigger a repost notification
  static void simulateRepostNotificationInApp({
    String? trackId,
    String? trackTitle,
    String? actorHandle,
    String? actorName,
    String? actorAvatarUrl,
  }) {
    if (!kDebugMode) return;

    try {
      final notification = _createNotification(
        id: 'debug-${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.repost,
        message: '${actorName ?? "User"} reposted "${trackTitle ?? "track"}"',
        actorId: actorHandle ?? 'test-user',
        actorDisplayName: actorName ?? 'Debug User',
        actorHandle: actorHandle ?? 'debuguser',
        actorAvatarUrl: actorAvatarUrl ?? '',
        entityType: 'track',
        entityId: trackId ?? 'track-debug-123',
        trackName: trackTitle ?? 'Debug Track',
      );

      _emitNotificationToBloc(notification);
    } catch (e) {
      debugPrint('❌ Error: $e');
    }
  }

  /// Trigger a like notification
  static void simulateLikeNotificationInApp({
    String? trackId,
    String? trackTitle,
    String? actorHandle,
    String? actorName,
    String? actorAvatarUrl,
  }) {
    if (!kDebugMode) return;

    try {
      final notification = _createNotification(
        id: 'debug-${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.like,
        message: '${actorName ?? "User"} liked "${trackTitle ?? "track"}"',
        actorId: actorHandle ?? 'test-user',
        actorDisplayName: actorName ?? 'Debug User',
        actorHandle: actorHandle ?? 'debuguser',
        actorAvatarUrl: actorAvatarUrl ?? '',
        entityType: 'track',
        entityId: trackId ?? 'track-debug-456',
        trackName: trackTitle ?? 'Debug Track',
      );

      _emitNotificationToBloc(notification);
    } catch (e) {
      debugPrint('❌ Error: $e');
    }
  }

  /// Trigger a follow notification
  static void simulateFollowNotificationInApp({
    String? actorHandle,
    String? actorName,
    String? actorAvatarUrl,
  }) {
    if (!kDebugMode) return;

    try {
      final notification = _createNotification(
        id: 'debug-${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.follow,
        message: '${actorName ?? "User"} followed you',
        actorId: actorHandle ?? 'test-follower',
        actorDisplayName: actorName ?? 'Debug Follower',
        actorHandle: actorHandle ?? 'debugfollower',
        actorAvatarUrl: actorAvatarUrl ?? '',
        entityType: 'user',
        entityId: actorHandle ?? 'test-follower',
        trackName: '',
      );

      _emitNotificationToBloc(notification);
    } catch (e) {
      debugPrint('❌ Error: $e');
    }
  }
}
