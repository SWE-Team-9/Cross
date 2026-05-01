import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../../../core/network/api_constants.dart';
import '../dto/socket_message_event_dto.dart';

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
    if (_isConnected || _socket?.connected == true) return;

    final baseUri = Uri.parse(ApiConstants.baseUrl);

    final cookies = await cookieJar.loadForRequest(baseUri);
    final cookieHeader =
        cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ');

    _socket = IO.io(
      ApiConstants.baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
        .setPath(ApiConstants.messagingBase)
          .setExtraHeaders(
            cookieHeader.isEmpty
                ? <String, String>{}
                : {'Cookie': cookieHeader},
          )
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      _hasEmittedConnectionError = false;
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
    });

    _socket!.onConnectError((dynamic error) {
      _isConnected = false;
      if (!_hasEmittedConnectionError) {
        _controller.addError(error);
        _hasEmittedConnectionError = true;
      }
    });

    _socket!.onError((dynamic error) {
      if (!_hasEmittedConnectionError) {
        _controller.addError(error);
        _hasEmittedConnectionError = true;
      }
    });

    _socket!.onReconnect((_) {
      _isConnected = true;
      _hasEmittedConnectionError = false;
    });

    _socket!.onReconnectError((dynamic error) {
      _isConnected = false;
      if (!_hasEmittedConnectionError) {
        _controller.addError(error);
        _hasEmittedConnectionError = true;
      }
    });

    _socket!.onAny((String event, dynamic data) {
      try {
        if (data is! Map) return;

        final dto = SocketMessageEventDto.fromJson(
          Map<String, dynamic>.from(data),
        );

        _controller.add(dto);
      } catch (e, stackTrace) {
        _controller.addError(e, stackTrace);
      }
    });

    _socket!.connect();
  }

  @override
  Future<void> disconnect() async {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;

    _isConnected = false;
  }

  Future<void> dispose() async {
    await disconnect();
    await _controller.close();
  }
}
