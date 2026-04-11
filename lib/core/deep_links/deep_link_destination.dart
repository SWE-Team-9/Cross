// core/deep_links/deep_link_destination.dart

/// Represents every possible destination a deep link can resolve to.
///
/// Sealed so the compiler enforces exhaustive handling at every call site.
/// Each subtype carries only the data it needs — nothing more.
sealed class DeepLinkDestination {
  const DeepLinkDestination();
}

/// soundclone://track/{trackId}
/// Opens the full player / track detail screen.
final class TrackDeepLink extends DeepLinkDestination {
  const TrackDeepLink({required this.trackId});

  final String trackId;
}

/// soundclone://track/secret/{secretToken}
/// Opens a private track shared via its 24-char nanoid token.
final class SecretTrackDeepLink extends DeepLinkDestination {
  const SecretTrackDeepLink({required this.secretToken});

  final String secretToken;
}

/// soundclone://user/{handle}
/// Opens a user profile by their @handle.
final class ProfileDeepLink extends DeepLinkDestination {
  const ProfileDeepLink({required this.handle});

  final String handle;
}

/// soundclone://playlist/{playlistId}
/// Stub — Module 7 not done yet. Route exists but shows placeholder.
final class PlaylistDeepLink extends DeepLinkDestination {
  const PlaylistDeepLink({required this.playlistId});

  final String playlistId;
}

/// soundclone://search?q={query}
/// Stub — Module 8 not done yet. Route exists but shows placeholder.
final class SearchDeepLink extends DeepLinkDestination {
  const SearchDeepLink({required this.query});

  final String query;
}

/// Catch-all for anything that doesn't match a known pattern.
/// [reason] explains why it failed — used for logging and snackbar message.
final class InvalidDeepLink extends DeepLinkDestination {
  const InvalidDeepLink({required this.reason});

  final String reason;
}
