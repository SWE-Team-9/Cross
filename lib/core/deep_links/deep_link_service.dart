// core/deep_links/deep_link_service.dart

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:injectable/injectable.dart';

import 'deep_link_destination.dart';
import 'deep_link_parser.dart';

/// Owns the OS-level deep link listener for the lifetime of the app.
///
/// - Handles cold start (app launched via link) via [getInitialLink].
/// - Handles warm start (app already running) via [uriLinkStream].
/// - Parses every incoming URI through [DeepLinkParser].
/// - Exposes [stream] for the router to listen to.
///
/// Register as @lazySingleton so only one OS listener is ever active.
@lazySingleton
class DeepLinkService {
  DeepLinkService() : _appLinks = AppLinks();

  final AppLinks _appLinks;

  // Internal broadcast controller — allows multiple listeners (router, etc.)
  final StreamController<DeepLinkDestination> _controller =
      StreamController<DeepLinkDestination>.broadcast();

  /// The stream of parsed deep link destinations.
  /// The router subscribes to this.
  Stream<DeepLinkDestination> get stream => _controller.stream;

  /// Call once in main() or in your app's initState.
  /// Sets up both cold-start and warm-start handling.
  Future<void> init() async {
    // ── Cold start ────────────────────────────────────────────────────────
    // If the app was launched by tapping a deep link, this returns that URI.
    // If the app launched normally, this returns null.
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _emit(initialUri);
      }
    } catch (_) {
      // If cold-start link retrieval fails, we just continue normally.
      // Never crash the app over a failed deep link.
    }

    // ── Warm start ────────────────────────────────────────────────────────
    // Listen for links while the app is already running.
    _appLinks.uriLinkStream.listen(
      _emit,
      onError: (_) {
        // Silently ignore stream errors — bad links shouldn't crash the app.
      },
    );
  }

  /// Parses the URI and adds the result to the stream.
  void _emit(Uri uri) {
    final DeepLinkDestination destination = DeepLinkParser.parse(uri);
    _controller.add(destination);
  }

  /// Clean up when the singleton is disposed (app shutdown).
  Future<void> dispose() async {
    await _controller.close();
  }
}