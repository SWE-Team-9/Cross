// // lib/features/search/data/datasources/genre_remote_datasource.dart

// import 'package:injectable/injectable.dart';

// import '../../../../core/models/track.dart';
// import '../../../../core/network/dio_client.dart';
// import '../../../../core/network/api_constants.dart';
// import '../../../search/domain/entities/search_entities.dart';
// import '../../domain/entities/genre_entities.dart';

// @lazySingleton
// class GenreRemoteDatasource {
//   final DioClient _client;
//   GenreRemoteDatasource(this._client);

//   // ─────────────────────────────────────────────────────────────────────────
//   // Public entry-point
//   // ─────────────────────────────────────────────────────────────────────────

//   Future<GenrePageData> fetchGenrePage(String genreSlug) async {
//     final results = await Future.wait([
//       _fetchTrending(genreSlug),
//       _fetchPlaylists(genreSlug),
//       _fetchDiscoverMore(genreSlug),
//       _fetchSuggestedProfiles(),
//       _fetchMyFollowingIds(),
//     ]);

//     final trending     = results[0] as List<Track>;
//     final playlists    = results[1] as List<PlaylistEntity>;
//     final discoverMore = results[2] as List<Track>;
//     final profiles     = results[3] as List<GenreProfileEntity>;
//     final followingIds = results[4] as Set<String>;

//     // Introducing = most-liked track; next 2 shown under it
//     Track? introducing;
//     List<Track> introducingExtras = [];
//     if (trending.isNotEmpty) {
//       final byLikes = List<Track>.from(trending)
//         ..sort((a, b) => b.likesCount.compareTo(a.likesCount));
//       introducing       = byLikes.first;
//       introducingExtras = byLikes.skip(1).take(2).toList();
//     }

//     return GenrePageData(
//       headerImageUrl:    trending.isNotEmpty ? (trending.first.artworkUrl ?? '') : '',
//       trending:          trending,
//       introducing:       introducing,
//       introducingExtras: introducingExtras,
//       playlists:         playlists,
//       albums:            [],
//       profiles:          profiles,
//       discoverMore:      discoverMore,
//       followingIds:      followingIds,
//     );
//   }

//   // ─────────────────────────────────────────────────────────────────────────
//   // GET /api/v1/discovery/trending/genres/{genreSlug}/tracks
//   // Response: { genre:{slug,name}, limit:n, total:n, tracks:[...] }
//   // ─────────────────────────────────────────────────────────────────────────

//   Future<List<Track>> _fetchTrending(String genreSlug) async {
//     try {
//       final r = await _client.get<Map<String, dynamic>>(
//         '/api/v1/discovery/trending/genres/$genreSlug/tracks',
//         queryParameters: {'limit': 50},
//       );
//       final body = r.data as Map<String, dynamic>? ?? {};
//       final list = (body['tracks'] as List<dynamic>? ?? [])
//           .cast<Map<String, dynamic>>();
//       return list.map(_parseTrack).toList();
//     } catch (_) {
//       return [];
//     }
//   }

//   // ─────────────────────────────────────────────────────────────────────────
//   // Playlists  GET /api/v1/playlists?genre=<slug>&limit=20
//   // ─────────────────────────────────────────────────────────────────────────

//   Future<List<PlaylistEntity>> _fetchPlaylists(String genreSlug) async {
//     try {
//       final r = await _client.get<Map<String, dynamic>>(
//         ApiConstants.playlistsBase,
//         queryParameters: {'genre': genreSlug, 'limit': 20},
//       );
//       return _extractList(r.data as Map<String, dynamic>?)
//           .map(_parsePlaylist)
//           .toList();
//     } catch (_) {
//       return [];
//     }
//   }

//   // ─────────────────────────────────────────────────────────────────────────
//   // Discover more  — reuse global search, filter by genre slug client-side
//   // ─────────────────────────────────────────────────────────────────────────

//   Future<List<Track>> _fetchDiscoverMore(String genreSlug) async {
//     try {
//       final r = await _client.get<Map<String, dynamic>>(
//         ApiConstants.globalSearch,
//         queryParameters: {'q': genreSlug, 'kind': 'track', 'limit': 30},
//       );
//       final slug = genreSlug.toLowerCase();
//       return _extractList(r.data as Map<String, dynamic>?)
//           .map(_parseTrack)
//           .where((t) {
//             final g = (t.genre ?? '').toLowerCase();
//             return g == slug || g.contains(slug) || g.isEmpty;
//           })
//           .toList();
//     } catch (_) {
//       return [];
//     }
//   }

//   // ─────────────────────────────────────────────────────────────────────────
//   // Suggested profiles  GET /api/v1/social/suggestions
//   // ─────────────────────────────────────────────────────────────────────────

//   Future<List<GenreProfileEntity>> _fetchSuggestedProfiles() async {
//     try {
//       final r = await _client.get<Map<String, dynamic>>(
//         ApiConstants.suggestedUsersPath,
//         queryParameters: {'limit': 10},
//       );
//       return _extractList(r.data as Map<String, dynamic>?)
//           .map(_parseProfile)
//           .toList();
//     } catch (_) {
//       return [];
//     }
//   }

//   // ─────────────────────────────────────────────────────────────────────────
//   // My following IDs  (lightweight endpoint, falls back to empty)
//   // ─────────────────────────────────────────────────────────────────────────

//   Future<Set<String>> _fetchMyFollowingIds() async {
//     try {
//       final r = await _client.get<Map<String, dynamic>>(
//         '${ApiConstants.socialBase}/me/following-ids',
//       );
//       final body = r.data as Map<String, dynamic>? ?? {};
//       final list = body['ids'] as List<dynamic>?
//           ?? body['following_ids'] as List<dynamic>?
//           ?? [];
//       return list.map((e) => e.toString()).toSet();
//     } catch (_) {
//       return {};
//     }
//   }

//   // ─────────────────────────────────────────────────────────────────────────
//   // Follow / Unfollow  PUT|DELETE /api/v1/social/follow/<userId>
//   // ─────────────────────────────────────────────────────────────────────────

//   Future<void> followUser({required String userId, required bool follow}) async {
//     final path = ApiConstants.followUserPath(userId);
//     if (follow) {
//       await _client.put<dynamic>(path);
//     } else {
//       await _client.delete<dynamic>(path);
//     }
//   }

//   // ─────────────────────────────────────────────────────────────────────────
//   // Parsers — match the real API response shape:
//   //
//   // {
//   //   "trackId":     "uuid",
//   //   "title":       "Example Track",
//   //   "slug":        "example-track",
//   //   "artist":      { "id":"uuid", "displayName":"...", "handle":"...", "avatarUrl":null },
//   //   "genre":       { "slug":"electronic", "name":"Electronic" },
//   //   "coverArtUrl": null,
//   //   "durationMs":  210000,
//   //   "likesCount":  42,
//   //   "repostsCount":7,
//   //   "createdAt":   "2026-01-01T00:00:00.000Z"
//   // }
//   // ─────────────────────────────────────────────────────────────────────────

//   Track _parseTrack(Map<String, dynamic> j) {
//     final artist    = j['artist'] as Map<String, dynamic>? ?? {};
//     final genreMap  = j['genre']  as Map<String, dynamic>? ?? {};

//     // durationMs (API) → seconds (Track model)
//     final durationMs  = _i(j['durationMs'] ?? j['duration_ms'] ?? j['duration']);
//     final durationSec = durationMs > 1000 ? durationMs ~/ 1000 : durationMs;

//     return Track(
//       // Use whichever ID field the API sends
//       id:            _s(j['trackId'] ?? j['id']),
//       title:         _s(j['title']),
//       // Artist name comes from nested artist object
//       artist:        _s(artist['displayName'] ?? artist['handle'] ?? j['artist']),
//       // Cover art field name in this API is coverArtUrl
//       artworkUrl:    (j['coverArtUrl'] ?? j['artwork_url'] ?? j['artworkUrl']) as String?,
//       likesCount:    _i(j['likesCount']    ?? j['likes_count']),
//       repostsCount:  _i(j['repostsCount']  ?? j['reposts_count']),
//       // Map to whichever field name Track uses — see note below
//       durationSeconds: durationSec,
//       handle:        _s(artist['handle']   ?? j['handle']),
//       // Store genre slug for client-side filtering
//       genre:         _s(genreMap['slug']   ?? genreMap['name'] ?? j['genre']),
//     );
//   }

//   PlaylistEntity _parsePlaylist(Map<String, dynamic> j) {
//     final user = j['user'] as Map<String, dynamic>? ?? {};
//     return PlaylistEntity(
//       id:         _s(j['id']),
//       title:      _s(j['title']),
//       artworkUrl: _s(j['artwork_url'] ?? j['artworkUrl'] ?? j['coverArtUrl']),
//       ownerName:  _s(j['owner_name']  ?? user['displayName'] ?? user['username']),
//       trackCount: _i(j['track_count'] ?? j['trackCount']     ?? j['tracks_count']),
//       isPrivate:  j['sharing'] == 'private' || j['is_private'] == true,
//     );
//   }

//   GenreProfileEntity _parseProfile(Map<String, dynamic> j) {
//     return GenreProfileEntity(
//       id:          _s(j['id']),
//       username:    _s(j['handle']      ?? j['username']     ?? j['permalink']),
//       displayName: _s(j['displayName'] ?? j['display_name'] ?? j['full_name'] ?? j['username']),
//       avatarUrl:   _s(j['avatarUrl']   ?? j['avatar_url']   ?? j['profile_picture']),
//       isVerified:  j['verified'] as bool? ?? false,
//     );
//   }

//   // ─────────────────────────────────────────────────────────────────────────
//   // Utilities
//   // ─────────────────────────────────────────────────────────────────────────

//   List<Map<String, dynamic>> _extractList(Map<String, dynamic>? body) {
//     if (body == null) return [];
//     for (final key in ['tracks', 'collection', 'playlists', 'users', 'data', 'results']) {
//       if (body[key] is List) {
//         return (body[key] as List).cast<Map<String, dynamic>>();
//       }
//     }
//     return [];
//   }

//   String _s(dynamic v) => v?.toString() ?? '';
//   int    _i(dynamic v) => (v as num?)?.toInt() ?? 0;
// }