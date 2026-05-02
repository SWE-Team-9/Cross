// lib/features/search/data/dto/search_models.dart

import '../../domain/entities/search_entities.dart';

class SearchResponseModel {
  final List<TrackModel> tracks;
  final List<UserModel> users;
  final List<PlaylistModel> playlists;
  final SearchMetaModel meta;

  const SearchResponseModel({
    required this.tracks,
    required this.users,
    required this.playlists,
    required this.meta,
  });

  factory SearchResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    return SearchResponseModel(
      tracks: _parseList(data['tracks'], TrackModel.fromJson),
      users: _parseList(data['users'], UserModel.fromJson),
      playlists: _parseList(data['playlists'], PlaylistModel.fromJson),
      meta: SearchMetaModel.fromJson(meta),
    );
  }

  static List<T> _parseList<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw is! List) return [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList(growable: false);
  }

  SearchResultsEntity toEntity() => SearchResultsEntity(
        tracks: tracks,
        users: users,
        playlists: playlists,
        meta: meta.toEntity(),
      );
}

// ── Meta ──────────────────────────────────────────────────────────────────────

class SearchMetaModel {
  final int currentPage;
  final int totalResults;
  final int totalPages;

  const SearchMetaModel({
    required this.currentPage,
    required this.totalResults,
    required this.totalPages,
  });

  factory SearchMetaModel.fromJson(Map<String, dynamic> json) =>
      SearchMetaModel(
        currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
        totalResults: (json['total_results'] as num?)?.toInt() ?? 0,
        totalPages: (json['total_pages'] as num?)?.toInt() ?? 0,
      );

  SearchMetaEntity toEntity() => SearchMetaEntity(
        currentPage: currentPage,
        totalResults: totalResults,
        totalPages: totalPages,
      );
}

// ── Track ─────────────────────────────────────────────────────────────────────

class TrackModel extends TrackEntity {
  const TrackModel({
    required super.id,
    required super.title,
    required super.artistName,
    required super.artworkUrl,
    required super.streamUrl,
    required super.duration,
    required super.playbackCount,
    required super.likesCount,
    required super.genre,
    required super.isPrivate,
    required super.createdAt,
  });

  factory TrackModel.fromJson(Map<String, dynamic> j) => TrackModel(
        id: j['id']?.toString() ?? '',
        title: j['title'] as String? ?? '',
        artistName: j['artistHandle'] as String? ??
            j['artist_handle'] as String? ??
            (j['user'] as Map<String, dynamic>?)?['username'] as String? ??
            '',
        artworkUrl: j['coverArtUrl'] as String? ??
            j['cover_art_url'] as String? ??
            j['artwork_url'] as String? ??
            '',
        streamUrl:
            j['streamUrl'] as String? ?? j['stream_url'] as String? ?? '',
        duration: Duration(
          seconds: (j['duration'] as num?)?.toInt() ?? 0,
        ),
        playbackCount: (j['views'] as num?)?.toInt() ??
            (j['playback_count'] as num?)?.toInt() ??
            0,
        likesCount: (j['likesCount'] as num?)?.toInt() ??
            (j['likes_count'] as num?)?.toInt() ??
            0,
        genre: j['genre'] as String? ?? '',
        isPrivate: j['sharing'] == 'private' || // ← التصحيح
            (j['isPrivate'] as bool? ?? false),
        createdAt: DateTime.tryParse(
              j['createdAt'] as String? ?? j['created_at'] as String? ?? '',
            ) ??
            DateTime(1970),
      );
}

// ── User ──────────────────────────────────────────────────────────────────────

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.username,
    required super.displayName,
    required super.avatarUrl,
    required super.followersCount,
    required super.trackCount,
    required super.verified,
    required super.city,
    required super.country,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['userId']?.toString() ?? j['id']?.toString() ?? '',
        username: j['handle'] as String? ??
            j['permalink'] as String? ??
            j['username'] as String? ??
            '',
        displayName: j['displayName'] as String? ??
            j['display_name'] as String? ??
            j['username'] as String? ??
            '',
        avatarUrl:
            j['avatarUrl'] as String? ?? j['avatar_url'] as String? ?? '',
        followersCount: (j['followersCount'] as num?)?.toInt() ??
            (j['followers_count'] as num?)?.toInt() ??
            0,
        trackCount: (j['trackCount'] as num?)?.toInt() ??
            (j['track_count'] as num?)?.toInt() ??
            0,
        verified: j['verified'] as bool? ?? false,
        city: j['city'] as String? ?? '',
        country: j['country'] as String? ?? '',
      );
}

// ── Playlist ──────────────────────────────────────────────────────────────────

class PlaylistModel extends PlaylistEntity {
  const PlaylistModel({
    required super.id,
    required super.title,
    required super.artworkUrl,
    required super.trackCount,
    required super.ownerName,
    required super.isAlbum,
    required super.isPrivate,
    required super.duration,
    required super.likesCount,
    required super.createdAt,
  });

  factory PlaylistModel.fromJson(Map<String, dynamic> j) => PlaylistModel(
        id: j['id']?.toString() ?? '',
        title: j['title'] as String? ?? '',
        artworkUrl: j['coverArtUrl'] as String? ??
            j['artwork_url'] as String? ??
            _firstTrackArtwork(j['tracks']) ??
            '',
        trackCount: (j['trackCount'] as num?)?.toInt() ??
            (j['track_count'] as num?)?.toInt() ??
            0,
        ownerName:
            (j['user'] as Map<String, dynamic>?)?['username'] as String? ??
                j['ownerName'] as String? ??
                '',
        isAlbum: j['is_album'] as bool? ?? j['isAlbum'] as bool? ?? false,
        isPrivate: j['sharing'] == 'private' || // ← التصحيح
            (j['isPrivate'] as bool? ?? false),
        duration: Duration(
          seconds: (j['duration'] as num?)?.toInt() ?? 0,
        ),
        likesCount: (j['likesCount'] as num?)?.toInt() ??
            (j['likes_count'] as num?)?.toInt() ??
            0,
        createdAt: DateTime.tryParse(
              j['createdAt'] as String? ?? j['created_at'] as String? ?? '',
            ) ??
            DateTime(1970),
      );

  static String? _firstTrackArtwork(dynamic tracks) {
    if (tracks is! List || tracks.isEmpty) return null;
    final first = tracks.first;
    if (first is! Map<String, dynamic>) return null;
    return first['coverArtUrl'] as String? ?? first['artwork_url'] as String?;
  }
}
