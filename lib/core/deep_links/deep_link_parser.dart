import 'deep_link_destination.dart';

abstract final class DeepLinkParser {
  static const String _customScheme = 'iqa3';
  static const String _httpsHost = 'dev.iqa3.tech';

  static DeepLinkDestination parse(Uri uri) {
    // ── https://dev.iqa3.tech/... ──────────────────────────────────────────
    if (uri.scheme == 'https' && uri.host == _httpsHost) {
      return _parseHttpsPath(uri);
    }

    // ── soundclone://... ───────────────────────────────────────────────────
    if (uri.scheme == _customScheme) {
      return _parseCustomScheme(uri);
    }

    return InvalidDeepLink(reason: 'Unknown scheme: ${uri.scheme}');
  }

  // ── HTTPS path parser ────────────────────────────────────────────────────
  static DeepLinkDestination _parseHttpsPath(Uri uri) {
    final List<String> segments = uri.pathSegments;

    if (segments.isEmpty) {
      return const InvalidDeepLink(reason: 'Empty path');
    }

    switch (segments.first) {
      case 'track':
        return _parseTrack(segments.skip(1).toList());

      case 'playlist':
        return _parsePlaylist(segments.skip(1).toList());

      case 'search':
        return _parseSearch(uri.queryParameters);

      case 'user':
      case 'profile':
        return _parseUser(segments.skip(1).toList());

      // Web-only auth flows — لا تعترضها
      case 'reset-password':
      case 'verify-email':
      case 'auth':
        return InvalidDeepLink(
          reason: 'Web-only route — not handled by app: ${uri.path}',
        );

      default:
        return InvalidDeepLink(reason: 'Unknown path: ${uri.path}');
    }
  }

  // ── Custom scheme parser ─────────────────────────────────────────────────
  static DeepLinkDestination _parseCustomScheme(Uri uri) {
    final String host = uri.host;
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
      case 'oauth':
        return _parseOAuth(segments, uri.queryParameters);
      default:
        return InvalidDeepLink(reason: 'Unknown host: $host');
    }
  }

  static DeepLinkDestination _parseTrack(List<String> segments) {
    if (segments.isEmpty) {
      return const InvalidDeepLink(reason: 'Track link missing ID');
    }
    if (segments.first == 'secret') {
      if (segments.length < 2 || segments[1].isEmpty) {
        return const InvalidDeepLink(reason: 'Secret track link missing token');
      }
      return SecretTrackDeepLink(secretToken: segments[1]);
    }
    final String trackId = segments.first;
    if (trackId.isEmpty) {
      return const InvalidDeepLink(reason: 'Track ID is empty');
    }
    return TrackDeepLink(trackId: trackId);
  }

  static DeepLinkDestination _parseUser(List<String> segments) {
    if (segments.isEmpty || segments.first.isEmpty) {
      return const InvalidDeepLink(reason: 'User link missing handle');
    }
    return ProfileDeepLink(handle: segments.first);
  }

  static DeepLinkDestination _parsePlaylist(List<String> segments) {
    if (segments.isEmpty || segments.first.isEmpty) {
      return const InvalidDeepLink(reason: 'Playlist link missing ID');
    }
    if (segments.first == 'secret') {
      if (segments.length < 2 || segments[1].isEmpty) {
        return const InvalidDeepLink(reason: 'Secret playlist link missing token');
      }
      return SecretPlaylistDeepLink(secretToken: segments[1]);
    }
    return PlaylistDeepLink(playlistId: segments.first);
  }

  static DeepLinkDestination _parseSearch(Map<String, String> params) {
    final String? query = params['q'];
    if (query == null || query.trim().isEmpty) {
      return const InvalidDeepLink(reason: 'Search link missing query');
    }
    return SearchDeepLink(query: query.trim());
  }

  static DeepLinkDestination _parseOAuth(
    List<String> segments,
    Map<String, String> params,
  ) {
    if (segments.isEmpty || segments.first != 'callback') {
      return const InvalidDeepLink(
        reason: 'OAuth link must be soundclone://oauth/callback',
      );
    }
    final String? error = params['error'];
    final String? errorDescription = params['error_description'];
    if (error != null && error.trim().isNotEmpty) {
      return OAuthCallbackDeepLink(
        error: error.trim(),
        errorDescription: errorDescription?.trim(),
      );
    }
    final String? code = params['code'];
    final String? state = params['state'];
    if (code == null || code.trim().isEmpty) {
      return const InvalidDeepLink(
        reason: 'OAuth callback missing authorization code',
      );
    }
    return OAuthCallbackDeepLink(
      code: code.trim(),
      state: state?.trim(),
    );
  }
}