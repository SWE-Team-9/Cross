import 'package:injectable/injectable.dart';

import '../../../../core/models/track.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/genre_entities.dart';
import '../../domain/entities/search_entities.dart';

@lazySingleton
class GenreRemoteDatasource {
  final DioClient _client;

  GenreRemoteDatasource(this._client);

  Future<GenrePageData> fetchGenrePage(String genreSlug) async {
    final results = await Future.wait([
      _fetchTrending(genreSlug),
      _fetchPlaylists(genreSlug),
      _fetchDiscoverMore(genreSlug),
      _fetchSuggestedProfiles(genreSlug),
    ]);

    final trending = results[0] as List<Track>;
    final playlists = results[1] as List<PlaylistEntity>;
    final discoverMore = results[2] as List<Track>;
    final profiles = results[3] as List<GenreProfileEntity>;

    Track? introducing;
    List<Track> introducingExtras = const [];

    if (trending.isNotEmpty) {
      final sortedByLikes = List<Track>.from(trending)
        ..sort((a, b) => b.likesCount.compareTo(a.likesCount));
      introducing = sortedByLikes.first;
      introducingExtras = sortedByLikes.skip(1).take(2).toList();
    }

    return GenrePageData(
      headerImageUrl: trending.isNotEmpty ? trending.first.artworkUrl ?? '' : '',
      trending: trending,
      introducing: introducing,
      introducingExtras: introducingExtras,
      playlists: playlists,
      albums: const [],
      profiles: profiles,
      discoverMore: discoverMore,
      followingIds: const {},
    );
  }

  Future<List<Track>> _fetchTrending(String genreSlug) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.discoveryTrendingGenreTracksPath(genreSlug),
      queryParameters: {'limit': 50},
    );

    final body = response.data ?? <String, dynamic>{};
    final tracks = _extractList(body, const ['tracks', 'items', 'data']);

    return tracks.map(_parseTrack).toList(growable: false);
  }

  Future<List<PlaylistEntity>> _fetchPlaylists(String genreSlug) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.globalSearch,
      queryParameters: {
        'q': genreSlug,
        'type': 'playlist',
        'page': 1,
        'limit': 20,
      },
    );

    final body = response.data ?? <String, dynamic>{};
    final playlists = _extractNestedList(
      body,
      const ['playlists', 'items', 'data'],
    );

    return playlists.map(_parsePlaylist).toList(growable: false);
  }

  Future<List<Track>> _fetchDiscoverMore(String genreSlug) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.globalSearch,
      queryParameters: {
        'q': genreSlug,
        'type': 'track',
        'page': 1,
        'limit': 30,
      },
    );

    final body = response.data ?? <String, dynamic>{};
    final tracks = _extractNestedList(
      body,
      const ['tracks', 'items', 'data'],
    );

    final normalizedSlug = genreSlug.toLowerCase();

    return tracks
        .map(_parseTrack)
        .where((track) {
          final genre = (track.genre ?? '').toLowerCase();
          return genre.isEmpty ||
              genre == normalizedSlug ||
              genre.contains(normalizedSlug);
        })
        .toList(growable: false);
  }

  Future<List<GenreProfileEntity>> _fetchSuggestedProfiles(
    String genreSlug,
  ) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.globalSearch,
      queryParameters: {
        'q': genreSlug,
        'type': 'user',
        'page': 1,
        'limit': 10,
      },
    );

    final body = response.data ?? <String, dynamic>{};
    final users = _extractNestedList(
      body,
      const ['users', 'profiles', 'items', 'data'],
    );

    return users.map(_parseProfile).toList(growable: false);
  }

  Future<void> followUser({
    required String userId,
    required bool follow,
  }) async {
    final path = ApiConstants.followUserPath(userId);

    if (follow) {
      await _client.put<dynamic>(path);
    } else {
      await _client.delete<dynamic>(path);
    }
  }

  Track _parseTrack(Map<String, dynamic> json) {
    final artist = _map(json['artist']);
    final uploader = _map(json['uploader']);
    final uploaderProfile = _map(uploader['profile']);
    final genre = _map(json['genre']);

    return Track(
      id: _s(json['id'] ?? json['trackId']),
      title: _s(json['title']),
      artist: _s(
        artist['displayName'] ??
            artist['handle'] ??
            uploaderProfile['displayName'] ??
            uploaderProfile['handle'] ??
            json['artistName'] ??
            json['artistHandle'],
      ),
      audioUrl: _s(json['audioUrl'] ?? json['audio_url'] ?? json['streamUrl']),
      artworkUrl: _nullableString(
        json['coverArtUrl'] ?? json['artworkUrl'] ?? json['artwork_url'],
      ),
      handle: _nullableString(
        artist['handle'] ?? uploaderProfile['handle'] ?? json['artistHandle'],
      ),
      slug: _nullableString(json['slug']),
      artistId: _nullableString(
        artist['id'] ?? uploader['userId'] ?? json['artistId'] ?? json['uploaderId'],
      ),
      genre: _nullableString(
        genre['slug'] ?? genre['name'] ?? json['genre'],
      ),
      likesCount: _int(json['likesCount'] ?? json['likes_count']),
      repostsCount: _int(json['repostsCount'] ?? json['reposts_count']),
      durationMs: _nullableInt(json['durationMs'] ?? json['duration_ms']),
    );
  }

  PlaylistEntity _parsePlaylist(Map<String, dynamic> json) {
    final user = _map(json['user']);
    final owner = _map(json['owner']);

    return PlaylistEntity(
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

  GenreProfileEntity _parseProfile(Map<String, dynamic> json) {
    return GenreProfileEntity(
      id: _s(json['id'] ?? json['userId']),
      username: _s(json['handle'] ?? json['username'] ?? json['permalink']),
      displayName: _s(
        json['displayName'] ??
            json['display_name'] ??
            json['fullName'] ??
            json['username'] ??
            json['handle'],
      ),
      avatarUrl: _s(json['avatarUrl'] ?? json['avatar_url']),
      isVerified: json['verified'] as bool? ?? false,
    );
  }

  List<Map<String, dynamic>> _extractNestedList(
    Map<String, dynamic> body,
    List<String> keys,
  ) {
    final data = body['data'];

    if (data is Map) {
      final nested = Map<String, dynamic>.from(data);
      final nestedResult = _extractList(nested, keys);
      if (nestedResult.isNotEmpty) return nestedResult;
    }

    return _extractList(body, keys);
  }

  List<Map<String, dynamic>> _extractList(
    Map<String, dynamic> body,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = body[key];
      if (value is List) {
        return value
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false);
      }
    }

    return const [];
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
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

  static String _s(dynamic value) => value?.toString() ?? '';

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static int _int(dynamic value) {
    return _nullableInt(value) ?? 0;
  }

  static int? _nullableInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}