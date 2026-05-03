sealed class DeepLinkDestination {
  const DeepLinkDestination();
}

final class TrackDeepLink extends DeepLinkDestination {
  const TrackDeepLink({required this.trackId});

  final String trackId;
}

final class SecretTrackDeepLink extends DeepLinkDestination {
  const SecretTrackDeepLink({required this.secretToken});

  final String secretToken;
}

final class ProfileDeepLink extends DeepLinkDestination {
  const ProfileDeepLink({required this.handle});

  final String handle;
}

final class PlaylistDeepLink extends DeepLinkDestination {
  const PlaylistDeepLink({required this.playlistId});

  final String playlistId;
}

final class SecretPlaylistDeepLink extends DeepLinkDestination {
  const SecretPlaylistDeepLink({required this.secretToken});

  final String secretToken;
}

final class SearchDeepLink extends DeepLinkDestination {
  const SearchDeepLink({required this.query});

  final String query;
}

final class ResolvableResourceDeepLink extends DeepLinkDestination {
  const ResolvableResourceDeepLink({required this.url});

  final String url;
}

final class OAuthCallbackDeepLink extends DeepLinkDestination {
  const OAuthCallbackDeepLink({
    this.code,
    this.state,
    this.error,
    this.errorDescription,
  });

  final String? code;
  final String? state;
  final String? error;
  final String? errorDescription;

  bool get hasError => error != null && error!.trim().isNotEmpty;
}

final class InvalidDeepLink extends DeepLinkDestination {
  const InvalidDeepLink({required this.reason});

  final String reason;
}