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
    final data = _map(json['data']).isNotEmpty ? _map(json['data']) : json;
    final meta = _map(json['meta']);

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
    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map((item) => fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  SearchResultsEntity toEntity() {
    return SearchResultsEntity(
      tracks: tracks,
      users: users,
      playlists: playlists,
      meta: meta.toEntity(),
    );
  }
}

class SearchMetaModel {
  final int currentPage;
  final int totalResults;
  final int totalPages;

  const SearchMetaModel({
    required this.currentPage,
    required this.totalResults,
    required this.totalPages,
  });

  factory SearchMetaModel.fromJson(Map<String, dynamic> json) {
    return SearchMetaModel(
      currentPage: _int(
          json['current_page'] ?? json['currentPage'] ?? json['page'],
          fallback: 1),
      totalResults:
          _int(json['total_results'] ?? json['totalResults'] ?? json['total']),
      totalPages: _int(json['total_pages'] ?? json['totalPages']),
    );
  }

  SearchMetaEntity toEntity() {
    return SearchMetaEntity(
      currentPage: currentPage,
      totalResults: totalResults,
      totalPages: totalPages,
    );
  }
}

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

  factory TrackModel.fromJson(Map<String, dynamic> json) {
    final artist = _map(json['artist']);
    final uploader = _map(json['uploader']);
    final uploaderProfile = _map(uploader['profile']);
    final genre = _map(json['genre']);
    final stats = _map(json['stats']);

    return TrackModel(
      id: _s(json['id'] ?? json['trackId']),
      title: _s(json['title']),
      artistName: _s(
        json['artistName'] ??
            json['artistHandle'] ??
            artist['displayName'] ??
            artist['handle'] ??
            uploaderProfile['displayName'] ??
            uploaderProfile['handle'],
      ),
      artworkUrl: _s(
        json['coverArtUrl'] ??
            json['artworkUrl'] ??
            json['artwork_url'] ??
            json['cover_art_url'],
      ),
      streamUrl: _s(
        json['streamUrl'] ??
            json['stream_url'] ??
            json['audioUrl'] ??
            json['audio_url'],
      ),
      duration: _duration(json),
      playbackCount: _int(
        json['playsCount'] ??
            json['playbackCount'] ??
            json['playback_count'] ??
            json['views'] ??
            stats['playsCount'],
      ),
      likesCount: _int(
          json['likesCount'] ?? json['likes_count'] ?? stats['likesCount']),
      genre: _s(genre['slug'] ?? genre['name'] ?? json['genre']),
      isPrivate: json['sharing'] == 'private' ||
          json['visibility'] == 'PRIVATE' ||
          json['isPrivate'] == true ||
          json['is_private'] == true,
      createdAt: DateTime.tryParse(
            _s(json['createdAt'] ?? json['created_at'] ?? json['publishedAt']),
          ) ??
          DateTime(1970),
    );
  }
}

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
    super.isFollowing = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final profile = _map(json['profile']);

    return UserModel(
      id: _s(json['userId'] ?? json['id']),
      username: _s(
        json['handle'] ??
            json['permalink'] ??
            json['username'] ??
            profile['handle'],
      ),
      displayName: _s(
        json['displayName'] ??
            json['display_name'] ??
            json['username'] ??
            profile['displayName'] ??
            profile['handle'],
      ),
      avatarUrl:
          _s(json['avatarUrl'] ?? json['avatar_url'] ?? profile['avatarUrl']),
      followersCount: _int(json['followersCount'] ?? json['followers_count']),
      trackCount: _int(json['trackCount'] ?? json['track_count']),
      verified:
          json['verified'] as bool? ?? profile['verified'] as bool? ?? false,
      city: _s(json['city']),
      country: _s(json['country']),
      isFollowing:
          json['isFollowing'] as bool? ?? json['following'] as bool? ?? false,
    );
  }
}

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

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    final user = _map(json['user']);
    final owner = _map(json['owner']);

    return PlaylistModel(
      id: _s(json['id']),
      title: _s(json['title']),
      artworkUrl: _s(
        json['coverArtUrl'] ??
            json['artworkUrl'] ??
            json['artwork_url'] ??
            _firstTrackArtwork(json['tracks']),
      ),
      trackCount: _int(
        json['trackCount'] ?? json['track_count'] ?? json['tracksCount'],
      ),
      ownerName: _s(
        json['ownerName'] ??
            user['displayName'] ??
            user['username'] ??
            owner['displayName'] ??
            owner['username'],
      ),
      isAlbum: json['isAlbum'] as bool? ?? json['is_album'] as bool? ?? false,
      isPrivate: json['sharing'] == 'private' ||
          json['visibility'] == 'PRIVATE' ||
          json['isPrivate'] == true ||
          json['is_private'] == true,
      duration: Duration(
        milliseconds: _int(json['durationMs'] ?? json['duration_ms']),
      ),
      likesCount: _int(json['likesCount'] ?? json['likes_count']),
      createdAt: DateTime.tryParse(
            _s(json['createdAt'] ?? json['created_at']),
          ) ??
          DateTime(1970),
    );
  }

  static String? _firstTrackArtwork(dynamic tracks) {
    if (tracks is! List || tracks.isEmpty) return null;

    final first = tracks.first;
    if (first is! Map) return null;

    final map = Map<String, dynamic>.from(first);

    return _nullableString(
      map['coverArtUrl'] ?? map['artworkUrl'] ?? map['artwork_url'],
    );
  }
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

String _s(dynamic value) => value?.toString() ?? '';

String? _nullableString(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int _int(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

Duration _duration(Map<String, dynamic> json) {
  final durationMs = json['durationMs'] ?? json['duration_ms'];

  if (durationMs != null) {
    return Duration(milliseconds: _int(durationMs));
  }

  return Duration(seconds: _int(json['duration'] ?? json['durationSeconds']));
}
