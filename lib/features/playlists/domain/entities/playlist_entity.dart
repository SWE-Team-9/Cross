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
        return 'SECRET';
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
  final String? coverImageUrl;
  final PlaylistOwner? owner;
  final List<Track> tracks;
  final int tracksCount;
  final bool isLiked;

  const PlaylistEntity({
    required this.playlistId,
    required this.title,
    required this.description,
    required this.visibility,
    required this.secretToken,
    required this.coverImageUrl,
    required this.owner,
    required this.tracks,
    required this.tracksCount,
    this.isLiked = false,
  });

  bool get isSecret => visibility.isSecret;

  PlaylistEntity copyWith({
    String? playlistId,
    String? title,
    String? description,
    PlaylistVisibility? visibility,
    String? secretToken,
    bool clearSecretToken = false,
    String? coverImageUrl,
    bool clearCoverImageUrl = false,
    PlaylistOwner? owner,
    List<Track>? tracks,
    int? tracksCount,
    bool? isLiked,
  }) {
    return PlaylistEntity(
      playlistId: playlistId ?? this.playlistId,
      title: title ?? this.title,
      description: description ?? this.description,
      visibility: visibility ?? this.visibility,
      secretToken: clearSecretToken ? null : (secretToken ?? this.secretToken),
      coverImageUrl:
          clearCoverImageUrl ? null : (coverImageUrl ?? this.coverImageUrl),
      owner: owner ?? this.owner,
      tracks: tracks ?? this.tracks,
      tracksCount: tracksCount ?? this.tracksCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}
