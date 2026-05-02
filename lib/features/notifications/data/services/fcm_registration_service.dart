import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/notification_model.dart';
import '../../domain/entities/notification_entity.dart';
import '../../../messaging/domain/entities/conversation_entity.dart';
import '../../../messaging/domain/usecases/get_conversation_meta_usecase.dart';
import '../../../messaging/domain/usecases/get_or_create_direct_conversation_usecase.dart';
import '../../domain/entities/notifications_result.dart';
import '../../domain/usecases/device_use_cases.dart';

const AndroidNotificationChannel _fcmHighImportanceChannel =
    AndroidNotificationChannel(
  'high_importance_channel_v2',
  'High Importance Notifications',
  description: 'Used for important notification alerts.',
  importance: Importance.max,
);

final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
bool _localNotificationsInitialized = false;
Future<void> Function(String? payload)? _localNotificationTapHandler;

Future<void> _initializeLocalNotifications() async {
  if (_localNotificationsInitialized) {
    return;
  }

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);

  await _localNotificationsPlugin.initialize(initSettings);
  await _localNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (response) {
      final handler = _localNotificationTapHandler;
      if (handler != null) {
        unawaited(handler(response.payload));
      }
    },
  );

  await _localNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_fcmHighImportanceChannel);

  _localNotificationsInitialized = true;
}

Future<void> _showLocalNotification(RemoteMessage message) async {
  await _initializeLocalNotifications();

  final title = _extractTitle(message, const [
    'title',
    'notificationTitle',
    'notification_title',
  ]);
  final body = _extractBody(message, const [
    'body',
    'message',
    'text',
    'content',
    'notificationBody',
    'notification_body',
  ]);

  if ((title == null || title.trim().isEmpty) &&
      (body == null || body.trim().isEmpty)) {
    return;
  }

  final notificationId = _notificationIdFor(message);

  await _localNotificationsPlugin.show(
    notificationId,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'high_importance_channel_v2',
        'High Importance Notifications',
        channelDescription: 'Used for important notification alerts.',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.message,
        visibility: NotificationVisibility.public,
        fullScreenIntent: true,
      ),
    ),
    payload: message.data.isEmpty ? null : jsonEncode(message.data),
  );
}

int _notificationIdFor(RemoteMessage message) {
  final source = <String?>[
    message.messageId,
    message.sentTime?.microsecondsSinceEpoch.toString(),
    message.data['id']?.toString(),
    message.data['notificationId']?.toString(),
  ].firstWhere((value) => value != null && value.trim().isNotEmpty,
      orElse: () => DateTime.now().microsecondsSinceEpoch.toString());

  return source.hashCode & 0x7fffffff;
}

String? _extractTitle(RemoteMessage message, List<String> dataKeys) {
  final notificationTitle = message.notification?.title?.trim();
  if (notificationTitle != null && notificationTitle.isNotEmpty) {
    return notificationTitle;
  }

  for (final key in dataKeys) {
    final candidate = message.data[key]?.toString().trim();
    if (candidate != null && candidate.isNotEmpty) {
      return candidate;
    }
  }

  return null;
}

String? _extractBody(RemoteMessage message, List<String> dataKeys) {
  final notificationBody = message.notification?.body?.trim();
  if (notificationBody != null && notificationBody.isNotEmpty) {
    return notificationBody;
  }

  for (final key in dataKeys) {
    final candidate = message.data[key]?.toString().trim();
    if (candidate != null && candidate.isNotEmpty) {
      return candidate;
    }
  }

  return null;
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('=== FCM BACKGROUND MESSAGE RECEIVED ===');
  debugPrint('Message ID: ${message.messageId}');
  debugPrint('From: ${message.from}');
  debugPrint('Has notification: ${message.notification != null}');
  debugPrint('Data: ${message.data}');
  debugPrint('========================================');

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  // Android automatically displays notification payloads in background.
  // Show a local notification only for data-only messages.
  if (message.notification == null && message.data.isNotEmpty) {
    debugPrint('Showing local notification for data-only message');
    await _showLocalNotification(message);
  }
}

class FcmRegistrationService {
  FcmRegistrationService(
    this._registerDeviceUseCase,
    this._getConversationMetaUseCase,
    this._getOrCreateDirectConversationUseCase,
  );

  final RegisterDeviceUseCase _registerDeviceUseCase;
  final GetConversationMetaUseCase _getConversationMetaUseCase;
  final GetOrCreateDirectConversationUseCase
      _getOrCreateDirectConversationUseCase;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _openedMessageSubscription;
  HttpServer? _debugNotificationServer;
  bool _isInitialized = false;

  static const int _debugNotificationPort = 4040;

  final StreamController<void> _notificationRefreshController =
      StreamController<void>.broadcast();
  final StreamController<NotificationEntity> _notificationTapController =
      StreamController<NotificationEntity>.broadcast();
  final StreamController<ConversationEntity> _conversationOpenController =
      StreamController<ConversationEntity>.broadcast();

  ConversationEntity? _lastOpenedConversation;
  NotificationEntity? _lastOpenedNotification;

  Stream<void> get notificationRefreshStream =>
      _notificationRefreshController.stream;

  Stream<ConversationEntity> get conversationOpenStream =>
      _conversationOpenController.stream;

  Stream<NotificationEntity> get notificationTapStream =>
      _notificationTapController.stream;

  ConversationEntity? consumeLastOpenedConversation() {
    final conversation = _lastOpenedConversation;
    _lastOpenedConversation = null;
    return conversation;
  }

  NotificationEntity? consumeLastOpenedNotification() {
    final notification = _lastOpenedNotification;
    _lastOpenedNotification = null;
    return notification;
  }

  Future<void> initialize() async {
    if (!_isSupportedPlatform()) {
      return;
    }

    if (_isInitialized) {
      return;
    }

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }

    _localNotificationTapHandler = _handleLocalNotificationTap;
    await _initializeLocalNotifications();

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    await FirebaseMessaging.instance.setAutoInitEnabled(true);

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _tokenRefreshSubscription ??=
        FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);

    _foregroundMessageSubscription ??=
        FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('=== FCM FOREGROUND MESSAGE RECEIVED ===');
      debugPrint('Message ID: ${message.messageId}');
      debugPrint('From: ${message.from}');
      debugPrint('Has notification: ${message.notification != null}');
      debugPrint('Data: ${message.data}');
      debugPrint('========================================');
      await _showLocalNotification(message);
      _notificationRefreshController.add(null);
    });

    _openedMessageSubscription ??=
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _notificationRefreshController.add(null);
      _handleOpenedMessage(message);
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _notificationRefreshController.add(null);
      await _handleOpenedMessage(initialMessage);
    }

    if (kDebugMode) {
      await _startDebugNotificationServer();
    }

    _isInitialized = true;
  }

  Future<bool> syncToken() async {
    if (!_isSupportedPlatform()) {
      debugPrint('FCM syncToken: unsupported platform');
      return false;
    }

    await initialize();

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.trim().isEmpty) {
      debugPrint('FCM token is not available yet.');
      return false;
    }

    debugPrint('=== FCM TOKEN SYNC START ===');
    debugPrint('Token: $token');
    debugPrint('=============================');
    return _registerToken(token.trim());
  }

  Future<void> dispose() async {
    await _debugNotificationServer?.close(force: true);
    _debugNotificationServer = null;
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    await _foregroundMessageSubscription?.cancel();
    _foregroundMessageSubscription = null;
    await _openedMessageSubscription?.cancel();
    _openedMessageSubscription = null;
    await _notificationRefreshController.close();
    await _notificationTapController.close();
    _localNotificationTapHandler = null;
    await _conversationOpenController.close();
  }

  Future<void> _handleLocalNotificationTap(String? payload) async {
    final notification = await _parseNotificationPayload(payload);
    if (notification == null) return;

    _lastOpenedNotification = notification;
    _notificationTapController.add(notification);

    final conversation = await _resolveConversationForDataFromNotification(
      notification,
    );
    if (conversation == null) {
      return;
    }

    _lastOpenedConversation = conversation;
    _conversationOpenController.add(conversation);
  }

  Future<ConversationEntity?> _resolveConversationForMessage(
    RemoteMessage message,
  ) async {
    return _resolveConversationForData(message.data);
  }

  Future<ConversationEntity?> _resolveConversationForData(
    Map<String, dynamic> data,
  ) async {
    final kind = _normalizeKind(
      data['type'] ?? data['eventType'] ?? data['notificationType'],
    );

    if (!_looksLikeMessageKind(kind)) {
      return null;
    }

    final conversationId = _firstNonEmpty([
      data['conversationId'],
      data['conversation_id'],
      _extractConversationId(data['message']),
      _extractConversationId(data['conversation']),
    ]);

    if (conversationId.isNotEmpty) {
      try {
        return await _getConversationMetaUseCase(conversationId);
      } catch (_) {
        // Fall through and try to resolve by participant id.
      }
    }

    final participantId = _firstNonEmpty([
      data['receiverId'],
      data['receiver_id'],
      data['senderId'],
      data['sender_id'],
      data['actorId'],
      data['actor_id'],
      data['userId'],
      data['user_id'],
    ]);

    if (participantId.isEmpty) {
      return null;
    }

    try {
      return await _getOrCreateDirectConversationUseCase(
        receiverId: participantId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleOpenedMessage(RemoteMessage message) async {
    final notification = await _parseNotificationData(message.data);
    if (notification != null) {
      _lastOpenedNotification = notification;
      _notificationTapController.add(notification);
    }

    final conversation = await _resolveConversationForMessage(message);
    if (conversation == null) {
      return;
    }

    _lastOpenedConversation = conversation;
    _conversationOpenController.add(conversation);
  }

  Future<NotificationEntity?> _parseNotificationPayload(String? payload) async {
    if (payload == null || payload.trim().isEmpty) {
      return null;
    }

    try {
      final parsed = jsonDecode(payload);
      if (parsed is! Map) {
        return null;
      }

      return NotificationModel.fromJson(Map<String, dynamic>.from(parsed));
    } catch (_) {
      return null;
    }
  }

  Future<NotificationEntity?> _parseNotificationData(
    Map<String, dynamic> data,
  ) async {
    try {
      return NotificationModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<ConversationEntity?> _resolveConversationForDataFromNotification(
    NotificationEntity notification,
  ) async {
    final data = <String, dynamic>{
      'type': notification.type.name,
      'eventType': notification.type.name,
      'notificationType': notification.type.name,
      'conversationId': notification.entityType == 'conversation'
          ? notification.entityId
          : '',
      'receiverId': notification.actorId,
      'senderId': notification.actorId,
      'actorId': notification.actorId,
      'userId': notification.actorId,
    };

    return _resolveConversationForData(data);
  }

  static String _normalizeKind(dynamic raw) {
    return raw?.toString().trim().toLowerCase() ?? '';
  }

  static bool _looksLikeMessageKind(String kind) {
    return kind == 'message' ||
        kind == 'messages' ||
        kind == 'new_message' ||
        kind == 'newmessage' ||
        kind == 'new message' ||
        kind == 'message_created' ||
        kind == 'direct_message' ||
        kind == 'directmessage' ||
        kind == 'chat_message' ||
        kind == 'chatmessage';
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

  static String _extractConversationId(dynamic value) {
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      return _firstNonEmpty([
        map['conversationId'],
        map['conversation_id'],
        map['id'],
      ]);
    }

    return '';
  }

  RemoteMessage _buildDebugRemoteMessage(Map<String, dynamic> payload) {
    final actorName = (payload['actorName'] ?? 'Debug User').toString();
    final actorHandle = (payload['actorHandle'] ?? 'debuguser').toString();
    final actorAvatarUrl = (payload['actorAvatarUrl'] ?? '').toString();
    final trackId = (payload['trackId'] ?? 'debug-track-123').toString();
    final trackTitle = (payload['trackTitle'] ?? 'Debug Track').toString();
    final messageBody = '$actorName reposted your track "$trackTitle"';

    return RemoteMessage(
      messageId: 'debug-${DateTime.now().millisecondsSinceEpoch}',
      sentTime: DateTime.now(),
      from: 'debug-local',
      data: {
        'id': 'debug-${DateTime.now().millisecondsSinceEpoch}',
        'type': 'repost',
        'eventType': 'repost',
        'title': 'Track Reposted',
        'body': messageBody,
        'message': messageBody,
        'actorId': actorHandle,
        'actorHandle': actorHandle,
        'actorDisplayName': actorName,
        'actorAvatarUrl': actorAvatarUrl,
        'entityType': 'track',
        'entityId': trackId,
        'trackName': trackTitle,
        'isRead': 'false',
        'createdAt': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<bool> _registerToken(String token) async {
    final platform = _platformLabel();
    if (platform == null) {
      debugPrint('FCM _registerToken: platform label is null');
      return false;
    }

    debugPrint('=== FCM TOKEN REGISTRATION START ===');
    debugPrint('Platform: $platform');
    debugPrint('Token: $token');
    debugPrint('====================================');

    final result = await _registerDeviceUseCase(
      deviceToken: token,
      platform: platform,
    );

    switch (result) {
      case NotificationsSuccess<void>():
        debugPrint('=== FCM TOKEN REGISTRATION SUCCESS ===');
        debugPrint('Platform: $platform');
        debugPrint('Token: $token');
        debugPrint('=======================================');
        return true;
      case NotificationsFailure<void>(failure: final failure):
        debugPrint('=== FCM TOKEN REGISTRATION FAILED ===');
        debugPrint('Platform: $platform');
        debugPrint('Error: ${failure.message}');
        debugPrint('=====================================');
        return false;
    }

    return false;
  }

  bool _isSupportedPlatform() {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);
  }

  String? _platformLabel() {
    if (kIsWeb) {
      return null;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ANDROID'; 
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.macOS:
        return 'DESKTOP';
      case TargetPlatform.windows:
        return 'DESKTOP';
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
        return null;
    }
  }

  Future<void> _startDebugNotificationServer() async {
    try {
      _debugNotificationServer = await HttpServer.bind('127.0.0.1', _debugNotificationPort);
      debugPrint('Debug notification server started on http://127.0.0.1:$_debugNotificationPort');
      
      // Listen to requests without blocking the main thread
      unawaited(_debugNotificationServer!.forEach((request) async {
        if (request.method == 'POST' && request.uri.path == '/notify') {
          try {
            final body = await utf8.decoder.bind(request).join();
            final payload = jsonDecode(body) as Map<String, dynamic>;
            final message = _buildDebugRemoteMessage(payload);
            
            await _showLocalNotification(message);
            _notificationRefreshController.add(null);
            
            request.response
              ..statusCode = 200
              ..write('Notification sent')
              ..close();
          } catch (e) {
            request.response
              ..statusCode = 400
              ..write('Error: $e')
              ..close();
          }
        } else {
          request.response
            ..statusCode = 404
            ..write('Not found')
            ..close();
        }
      }));
    } catch (e) {
      debugPrint('Failed to start debug notification server: $e');
    }
  }
}
