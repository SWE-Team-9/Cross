import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../messaging/domain/entities/realtime_message_event_entity.dart';
import '../../../messaging/domain/usecases/connect_messaging_socket_usecase.dart';

class NotificationsRealtimeRefreshService {
  NotificationsRealtimeRefreshService(this._connectMessagingSocketUseCase);

  final ConnectMessagingSocketUseCase _connectMessagingSocketUseCase;

  final StreamController<void> _refreshController =
      StreamController<void>.broadcast();

  StreamSubscription<RealtimeMessageEventEntity>? _socketSubscription;
  bool _isStarted = false;

  Stream<void> get refreshStream => _refreshController.stream;

  Future<void> start() async {
    if (_isStarted) {
      return;
    }

    try {
      await _connectMessagingSocketUseCase();

      await _socketSubscription?.cancel();
      _socketSubscription = _connectMessagingSocketUseCase.eventsStream.listen(
        (event) {
          if (_shouldRefresh(event)) {
            _refreshController.add(null);
          }
        },
        onError: (error, stackTrace) {
          debugPrint('Notifications realtime socket error: $error');
          debugPrintStack(stackTrace: stackTrace);
        },
      );

      _isStarted = true;
    } catch (error, stackTrace) {
      debugPrint('Notifications realtime socket start failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> stop() async {
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    _isStarted = false;
  }

  Future<void> dispose() async {
    await stop();
    await _refreshController.close();
  }

  bool _shouldRefresh(RealtimeMessageEventEntity event) {
    if (event.currentUnreadCount != null) {
      return true;
    }

    switch (event.type) {
      case RealtimeMessageEventType.newMessage:
      case RealtimeMessageEventType.messageDeleted:
      case RealtimeMessageEventType.conversationRead:
      case RealtimeMessageEventType.conversationUpdated:
      case RealtimeMessageEventType.unreadCountUpdated:
        return true;
      case RealtimeMessageEventType.userBlocked:
      case RealtimeMessageEventType.userUnblocked:
      case RealtimeMessageEventType.unknown:
        return false;
    }
  }
}
