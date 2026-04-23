import 'dart:async';
import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:web_socket_channel/io.dart';

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

  IOWebSocketChannel? _channel;
  StreamSubscription? _subscription;

  bool _isConnected = false;

  MessagingSocketDataSourceImpl({
    required this.cookieJar,
  });

  @override
  Stream<SocketMessageEventDto> get eventsStream => _controller.stream;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<void> connect() async {
    if (_isConnected) return;

    final httpUri = Uri.parse(ApiConstants.baseUrl).resolve(
      ApiConstants.messagingBase,
    );

    final wsUri = httpUri.replace(
      scheme: httpUri.scheme == 'https' ? 'wss' : 'ws',
    );

    final cookies = await cookieJar.loadForRequest(httpUri);
    final cookieHeader = cookies
        .map((cookie) => '${cookie.name}=${cookie.value}')
        .join('; ');

    _channel = IOWebSocketChannel.connect(
      wsUri,
      headers: cookieHeader.isEmpty ? null : {'Cookie': cookieHeader},
      pingInterval: const Duration(seconds: 20),
    );

    _subscription = _channel!.stream.listen(
      (dynamic rawEvent) {
        try {
          final dynamic decoded =
              rawEvent is String ? jsonDecode(rawEvent) : rawEvent;

          if (decoded is! Map) return;

          final dto = SocketMessageEventDto.fromJson(
            Map<String, dynamic>.from(decoded)
          );

          _controller.add(dto);
        } catch (e, stackTrace) {
          _controller.addError(e, stackTrace);
        }
      },
      onDone: () {
        _isConnected = false;
      },
      onError: (Object error, StackTrace stackTrace) {
        _isConnected = false;
        _controller.addError(error, stackTrace);
      },
      cancelOnError: false,
    );

    _isConnected = true;
  }

  @override
  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;

    await _channel?.sink.close();
    _channel = null;

    _isConnected = false;
  }

  Future<void> dispose() async {
    await disconnect();
    await _controller.close();
  }
}