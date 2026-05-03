import 'dart:async';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../../core/config/app_config.dart';
import '../dto/socket_message_event_dto.dart'; // import صحيح من DTO

abstract class MessagingSocketDataSource {
  Stream<SocketMessageEventDto> get eventsStream;
  bool get isConnected;
  Future<void> connect();
  Future<void> disconnect();
}

class MessagingSocketDataSourceImpl implements MessagingSocketDataSource {
  final PersistCookieJar cookieJar;

  final StreamController<SocketMessageEventDto> _controller =
      StreamController<SocketMessageEventDto>.broadcast();

  IO.Socket? _socket;
  bool _isConnected = false;
  bool _hasEmittedConnectionError = false;

  MessagingSocketDataSourceImpl({
    required this.cookieJar,
  });

  @override
  Stream<SocketMessageEventDto> get eventsStream => _controller.stream;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<void> connect() async {
    print('[Socket] Attempting to connect...');

    final baseUri = Uri.parse(AppConfig.apiUrl);
    final cookies = await cookieJar.loadForRequest(baseUri);
    final cookieHeader =
        cookies.map((c) => '${c.name}=${c.value}').join('; ');

    print('[Socket] Cookies loaded: $cookieHeader');

    _socket = IO.io(
      '${AppConfig.apiUrl}/api/v1/messages', // Base URL for Socket.IO client
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setPath('/api/v1/socket.io') // Path from backend
          .setExtraHeaders(
              cookieHeader.isEmpty ? {} : {'Cookie': cookieHeader})
          .enableReconnection()
          .setReconnectionAttempts(99999)
          .setReconnectionDelay(2000)
          .build(),
    );

    print('[Socket] Socket initialized with URL and path.');

    // Event listeners
    _socket!.onConnect((_) {
      _isConnected = true;
      _hasEmittedConnectionError = false;
      print('[Socket] Connected successfully!');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      print('[Socket] Disconnected!');
    });

    _socket!.onConnectError((dynamic error) {
      _isConnected = false;
      print('[Socket] Connect error: $error');
      if (!_hasEmittedConnectionError) {
        _controller.addError(error);
        _hasEmittedConnectionError = true;
      }
    });

    _socket!.onError((dynamic error) {
      print('[Socket] Error received: $error');
      if (!_hasEmittedConnectionError) {
        _controller.addError(error);
        _hasEmittedConnectionError = true;
      }
    });

    _socket!.onReconnect((_) {
      _isConnected = true;
      _hasEmittedConnectionError = false;
      print('[Socket] Reconnected successfully!');
    });

    _socket!.onReconnectError((dynamic error) {
      _isConnected = false;
      print('[Socket] Reconnect error: $error');
      if (!_hasEmittedConnectionError) {
        _controller.addError(error);
        _hasEmittedConnectionError = true;
      }
    });

    _socket!.onAny((String event, dynamic data) {
      print('[Socket] Event received: $event, data: $data');
      try {
        final payload = _normalizeEventPayload(event, data);
        if (payload == null) return;

        final dto = SocketMessageEventDto.fromJson(payload);
        _controller.add(dto);
        print('[Socket] Event parsed and added to stream.');
      } catch (e, stackTrace) {
        print('[Socket] Error parsing event: $e');
        _controller.addError(e, stackTrace);
      }
    });

    print('[Socket] Starting connection...');
    _socket!.connect();
  }

  @override
  Future<void> disconnect() async {
    print('[Socket] Disconnecting...');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;

    _isConnected = false;
    print('[Socket] Disconnected and disposed.');
  }

  Future<void> dispose() async {
    print('[Socket] Disposing datasource...');
    await disconnect();
    await _controller.close();
    print('[Socket] Datasource disposed.');
  }

  Map<String, dynamic>? _normalizeEventPayload(String event, dynamic data) {
    final eventType = _socketEventTypeName(event);

    if (data is Map<String, dynamic>) {
      return eventType == null || data.containsKey('type')
          ? data
          : <String, dynamic>{...data, 'type': eventType};
    }

    if (data is Map) {
      final payload = Map<String, dynamic>.from(data);
      return eventType == null || payload.containsKey('type')
          ? payload
          : <String, dynamic>{...payload, 'type': eventType};
    }

    if (data is List && data.isNotEmpty) {
      final first = data.first;
      if (first is Map<String, dynamic>) {
        return eventType == null || first.containsKey('type')
            ? first
            : <String, dynamic>{...first, 'type': eventType};
      }

      if (first is Map) {
        final payload = Map<String, dynamic>.from(first);
        return eventType == null || payload.containsKey('type')
            ? payload
            : <String, dynamic>{...payload, 'type': eventType};
      }

      if (eventType != null) {
        return <String, dynamic>{
          'type': eventType,
          if (eventType == 'UNREAD_COUNT_UPDATED')
            'currentUnreadCount': first,
        };
      }
    }

    if (eventType == 'UNREAD_COUNT_UPDATED') {
      return <String, dynamic>{
        'type': eventType,
        'currentUnreadCount': data,
      };
    }

    return null;
  }

  String? _socketEventTypeName(String event) {
    final normalized = event.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    switch (normalized) {
      case 'newmessage':
      case 'messagecreated':
        return 'NEW_MESSAGE';
      case 'messagedeleted':
      case 'deletemessage':
        return 'MESSAGE_DELETED';
      case 'conversationread':
      case 'markread':
        return 'CONVERSATION_READ';
      case 'conversationupdated':
      case 'conversationarchived':
      case 'conversationunarchived':
        return 'CONVERSATION_UPDATED';
      case 'unreadcountupdated':
        return 'UNREAD_COUNT_UPDATED';
      case 'userblocked':
      case 'blocked':
        return 'USER_BLOCKED';
      case 'userunblocked':
      case 'unblocked':
        return 'USER_UNBLOCKED';
      default:
        return null;
    }
  }
}