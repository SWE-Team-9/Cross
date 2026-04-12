import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import 'deep_link_destination.dart';
import 'deep_link_parser.dart';

class DeepLinkService {
  DeepLinkService() : _appLinks = AppLinks();

  final AppLinks _appLinks;

  final StreamController<DeepLinkDestination> _controller =
      StreamController<DeepLinkDestination>.broadcast();

  DeepLinkDestination? _lastDestination;
  bool _lastDestinationConsumed = false;
  String? _lastEmittedUri;
  DateTime? _lastEmittedAt;

  Stream<DeepLinkDestination> get stream => _controller.stream;

  DeepLinkDestination? consumeLastDestination() {
    if (_lastDestinationConsumed) return null;
    _lastDestinationConsumed = true;
    return _lastDestination;
  }

  DeepLinkDestination? peekLastDestination() => _lastDestination;

  void markLastDestinationConsumed() {
    _lastDestinationConsumed = true;
  }

  Future<void> init() async {
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _emitIfNotDuplicate(initialUri, source: 'initial');
      }
    } catch (_) {}

    _appLinks.uriLinkStream.listen(
      (uri) {
        _lastDestinationConsumed = false;
        _emitIfNotDuplicate(uri, source: 'stream');
      },
      onError: (_) {},
    );
  }

  void _emitIfNotDuplicate(Uri uri, {required String source}) {
    final DateTime now = DateTime.now();
    final String currentUri = uri.toString();

    final bool isRecentDuplicate = _lastEmittedUri == currentUri &&
        _lastEmittedAt != null &&
        now.difference(_lastEmittedAt!) < const Duration(seconds: 2);

    if (isRecentDuplicate) {
      debugPrint('[DeepLinkService] Ignored duplicate ($source): $currentUri');
      return;
    }

    _lastEmittedUri = currentUri;
    _lastEmittedAt = now;
    _emit(uri);
  }

  void _emit(Uri uri) {
    final DeepLinkDestination destination = DeepLinkParser.parse(uri);
    _lastDestination = destination;
    _controller.add(destination);
    debugPrint('[DeepLinkService] Emitted: $destination');
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}