// core/deep_links/deep_link_parser.dart

import 'deep_link_destination.dart';

/// Parses an incoming URI into a typed [DeepLinkDestination].
///
/// Stateless and dependency-free — safe to call from anywhere,
/// and fully unit-testable without any Flutter setup.
abstract final class DeepLinkParser {
  /// The registered custom URL scheme for this app.
  static const String _scheme = 'soundclone';

  /// Entry point. Pass any URI and get back a typed destination.
  static DeepLinkDestination parse(Uri uri) {
    // Reject anything that isn't our custom scheme.
    // e.g. if somehow an https:// link gets passed in, we reject it cleanly.
    if (uri.scheme != _scheme) {
      return const InvalidDeepLink(
        reason: 'Unknown scheme: expected soundclone://',
      );
    }

    // uri.host is the first path segment in a custom scheme URL.
    // soundclone://track/abc  →  host = 'track', pathSegments = ['abc']
    // soundclone://user/amrdiab → host = 'user', pathSegments = ['amrdiab']
    final String host = uri.host;

    // uri.pathSegments gives us everything AFTER the host as a clean list.
    // soundclone://track/secret/abc → pathSegments = ['secret', 'abc']
    final List<String> segments = uri.pathSegments;

    switch (host) {
      case 'track':
        return _parseTrack(segments);

      case 'user':
        return _parseUser(segments);

      case 'playlist':
        return _parsePlaylist(segments);

      case 'search':
        return _parseSearch(uri.queryParameters);

      default:
        return InvalidDeepLink(reason: 'Unknown host: $host');
    }
  }

  // ── Private parsers ──────────────────────────────────────────────────────

  /// Handles both:
  ///   soundclone://track/{trackId}
  ///   soundclone://track/secret/{secretToken}
  static DeepLinkDestination _parseTrack(List<String> segments) {
    if (segments.isEmpty) {
      return const InvalidDeepLink(reason: 'Track link missing ID');
    }

    // soundclone://track/secret/{token}
    // segments = ['secret', 'V1StGXR8_Z5jdHi6B-myT-RQ']
    if (segments.first == 'secret') {
      if (segments.length < 2 || segments[1].isEmpty) {
        return const InvalidDeepLink(
          reason: 'Secret track link missing token',
        );
      }
      return SecretTrackDeepLink(secretToken: segments[1]);
    }

    // soundclone://track/{trackId}
    // segments = ['a1b2c3d4-e5f6-7890-abcd-ef1234567890']
    final String trackId = segments.first;
    if (trackId.isEmpty) {
      return const InvalidDeepLink(reason: 'Track ID is empty');
    }
    return TrackDeepLink(trackId: trackId);
  }

  /// Handles: soundclone://user/{handle}
  static DeepLinkDestination _parseUser(List<String> segments) {
    if (segments.isEmpty || segments.first.isEmpty) {
      return const InvalidDeepLink(reason: 'User link missing handle');
    }
    return ProfileDeepLink(handle: segments.first);
  }

  /// Handles: soundclone://playlist/{playlistId}
  /// Stub — backend Module 7 not implemented yet.
  static DeepLinkDestination _parsePlaylist(List<String> segments) {
    if (segments.isEmpty || segments.first.isEmpty) {
      return const InvalidDeepLink(reason: 'Playlist link missing ID');
    }
    return PlaylistDeepLink(playlistId: segments.first);
  }

  /// Handles: soundclone://search?q={query}
  /// Stub — backend Module 8 not implemented yet.
  static DeepLinkDestination _parseSearch(Map<String, String> params) {
    final String? query = params['q'];
    if (query == null || query.trim().isEmpty) {
      return const InvalidDeepLink(reason: 'Search link missing query');
    }
    return SearchDeepLink(query: query.trim());
  }
}