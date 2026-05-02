// lib/features/search/domain/entities/search_entities.dart

import 'package:equatable/equatable.dart';

// ══════════════════════════════════════════════════════════════════════════════
// RESULTS ROOT
// ══════════════════════════════════════════════════════════════════════════════

class SearchResultsEntity extends Equatable {
  final List<TrackEntity> tracks;
  final List<UserEntity> users;
  final List<PlaylistEntity> playlists;
  final SearchMetaEntity meta;

  const SearchResultsEntity({
    required this.tracks,
    required this.users,
    required this.playlists,
    required this.meta,
  });

  bool get isEmpty => tracks.isEmpty && users.isEmpty && playlists.isEmpty;

  bool get hasResults => !isEmpty;

  int get totalCount => tracks.length + users.length + playlists.length;

  @override
  List<Object?> get props => [tracks, users, playlists, meta];
}

// ══════════════════════════════════════════════════════════════════════════════
// META
// ══════════════════════════════════════════════════════════════════════════════

class SearchMetaEntity extends Equatable {
  final int currentPage;
  final int totalResults;
  final int totalPages;

  const SearchMetaEntity({
    required this.currentPage,
    required this.totalResults,
    required this.totalPages,
  });

  bool get hasMore => currentPage < totalPages;

  @override
  List<Object?> get props => [currentPage, totalResults, totalPages];
}

// ══════════════════════════════════════════════════════════════════════════════
// TRACK
// ══════════════════════════════════════════════════════════════════════════════

class TrackEntity extends Equatable {
  final String id;
  final String title;
  final String artistName;
  final String artworkUrl;
  final String streamUrl;
  final Duration duration;
  final int playbackCount;
  final int likesCount;
  final String genre;
  final bool isPrivate;
  final DateTime createdAt;

  const TrackEntity({
    required this.id,
    required this.title,
    required this.artistName,
    required this.artworkUrl,
    required this.streamUrl,
    required this.duration,
    required this.playbackCount,
    required this.likesCount,
    required this.genre,
    required this.isPrivate,
    required this.createdAt,
  });

  String get formattedDuration {
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = duration.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  List<Object?> get props => [id, title, artistName, streamUrl];
}

// ══════════════════════════════════════════════════════════════════════════════
// USER
// ══════════════════════════════════════════════════════════════════════════════

class UserEntity extends Equatable {
  final String id;
  final String username;
  final String displayName;
  final String avatarUrl;
  final int followersCount;
  final int trackCount;
  final bool verified;
  final String city;
  final String country;
  final bool isFollowing; // ← جديد

  const UserEntity({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.followersCount,
    required this.trackCount,
    required this.verified,
    required this.city,
    required this.country,
    this.isFollowing = false, // ← جديد
  });

  String get location => [city, country].where((s) => s.isNotEmpty).join(', ');

  @override
  List<Object?> get props => [id, username];
}

// ══════════════════════════════════════════════════════════════════════════════
// PLAYLIST
// ══════════════════════════════════════════════════════════════════════════════

class PlaylistEntity extends Equatable {
  final String id;
  final String title;
  final String artworkUrl;
  final int trackCount;
  final String ownerName;
  final bool isAlbum;
  final bool isPrivate;
  final Duration duration;
  final int likesCount;
  final DateTime createdAt;

  const PlaylistEntity({
    required this.id,
    required this.title,
    required this.artworkUrl,
    required this.trackCount,
    required this.ownerName,
    required this.isAlbum,
    required this.isPrivate,
    required this.duration,
    required this.likesCount,
    required this.createdAt,
  });

  String get kind => isAlbum ? 'Album' : 'Playlist';

  @override
  List<Object?> get props => [id, title, ownerName];
}
