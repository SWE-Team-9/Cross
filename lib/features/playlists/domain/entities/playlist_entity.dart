import 'package:soundcloud_clone/core/models/track.dart';

enum PlaylistVisibility {
  publicPlaylist,
  privatePlaylist,
}

extension PlaylistVisibilityX on PlaylistVisibility {
  String get apiValue {
    switch (this) {
      case PlaylistVisibility.publicPlaylist:
        return 'PUBLIC';
      case PlaylistVisibility.privatePlaylist:
        return 'PRIVATE';
    }
  }

  String get label {
    switch (this) {
      case PlaylistVisibility.publicPlaylist:
        return 'Public';
      case PlaylistVisibility.privatePlaylist:
        return 'Secret';
    }
  }

  bool get isSecret => this == PlaylistVisibility.privatePlaylist;
}

PlaylistVisibility playlistVisibilityFromApi(String? value) {
  final normalized = (value ?? '').trim().toUpperCase();
  if (normalized == 'PRIVATE' || normalized == 'SECRET') {
    return PlaylistVisibility.privatePlaylist;
  }
  return PlaylistVisibility.publicPlaylist;
}

class PlaylistOwner {
  final String id;
  final String displayName;

  const PlaylistOwner({
    required this.id,
    required this.displayName,
  });
}

class PlaylistEntity {
  final String playlistId;
  final String title;
  final String description;
  final PlaylistVisibility visibility;
  final String? secretToken;
  final PlaylistOwner? owner;
  final List<Track> tracks;
  final int tracksCount;

  const PlaylistEntity({
    required this.playlistId,
    required this.title,
    required this.description,
    required this.visibility,
    required this.secretToken,
    required this.owner,
    required this.tracks,
    required this.tracksCount,
  });

  bool get isSecret => visibility.isSecret;

  PlaylistEntity copyWith({
    String? playlistId,
    String? title,
    String? description,
    PlaylistVisibility? visibility,
    String? secretToken,
    bool clearSecretToken = false,
    PlaylistOwner? owner,
    List<Track>? tracks,
    int? tracksCount,
  }) {
    return PlaylistEntity(
      playlistId: playlistId ?? this.playlistId,
      title: title ?? this.title,
      description: description ?? this.description,
      visibility: visibility ?? this.visibility,
      secretToken: clearSecretToken ? null : (secretToken ?? this.secretToken),
      owner: owner ?? this.owner,
      tracks: tracks ?? this.tracks,
      tracksCount: tracksCount ?? this.tracksCount,
    );
  }
}
