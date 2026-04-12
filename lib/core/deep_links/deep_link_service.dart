// deep_link_service.dart

// Dart SDK
import 'dart:async';

// Flutter
import 'package:flutter/foundation.dart';

// Third-party
import 'package:app_links/app_links.dart';

// Project
import 'deep_link_destination.dart';
import 'deep_link_parser.dart';

class DeepLinkService {
  DeepLinkService() : _appLinks = AppLinks();

  final AppLinks _appLinks;

  // Use a broadcast stream with a stored last event
  // so the router listener gets it even if it subscribes late.
  final StreamController<DeepLinkDestination> _controller =
      StreamController<DeepLinkDestination>.broadcast();

  // Store last emitted destination so late subscribers can get it.
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

  Future<void> init() async {
    // ── Cold start ──────────────────────────────────────────────────────────
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _emitIfNotDuplicate(initialUri, source: 'initial');
      }
    } catch (_) {}

    // ── Warm start ──────────────────────────────────────────────────────────
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
    _lastDestination = destination; // store for late subscribers
    _controller.add(destination);
    debugPrint('[DeepLinkService] Emitted: $destination');
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
