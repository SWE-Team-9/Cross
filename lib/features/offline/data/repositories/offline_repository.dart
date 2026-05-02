import 'dart:io';
import 'dart:convert';

import 'package:path_provider/path_provider.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/network/api_constants.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineRepository {
  static const _tracksKey = 'offline_tracks';
  static const _trackDetailsKey = 'offline_track_details';
  static const _playlistsKey = 'offline_playlists';

  final DioClient dio;

  OfflineRepository(this.dio);

  // ───────────── DOWNLOAD ─────────────
  Future<String> downloadTrack(String trackId) async {
    // STEP 1: entitlement check
    await dio.get('/api/v1/subscriptions/offline/$trackId');

    // STEP 2: download audio bytes
    final response = await dio.get(
      '/api/v1/subscriptions/offline/$trackId/stream',
      options: Options(responseType: ResponseType.bytes),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$trackId.mp3');

    await file.writeAsBytes(response.data);

    return file.path;
  }

  Future<Track?> fetchTrackDetails(String trackId) async {
    try {
      final response = await dio.get(ApiConstants.trackByIdPath(trackId));
      final data = _asMap(_extractData(response.data));
      if (data.isEmpty) return null;
      return _trackFromJson(data);
    } catch (_) {
      return null;
    }
  }

  // ───────────── SAVE (PERSIST) ─────────────
  Future<void> saveDownloadedTracks(Map<String, String> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tracksKey, jsonEncode(data));
  }

  Future<void> saveDownloadedTrackDetails(Map<String, Track> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _trackDetailsKey,
      jsonEncode(
        data.map((key, value) => MapEntry(key, _trackToJson(value))),
      ),
    );
  }

  Future<void> saveDownloadedPlaylists(Map<String, PlaylistEntity> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _playlistsKey,
      jsonEncode(
        data.map((key, value) => MapEntry(key, _playlistToJson(value))),
      ),
    );
  }

  // ───────────── LOAD (PERSIST) ─────────────
  Future<Map<String, String>> getDownloadedTracks() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_tracksKey);

    if (json == null) return {};

    return Map<String, String>.from(jsonDecode(json));
  }

  Future<Map<String, Track>> getDownloadedTrackDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(_trackDetailsKey);
    if (rawJson == null) return {};

    final decoded = jsonDecode(rawJson);
    if (decoded is! Map) return {};

    return decoded.map((key, value) {
      return MapEntry(key.toString(), _trackFromJson(_asMap(value)));
    });
  }

  Future<Map<String, PlaylistEntity>> getDownloadedPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(_playlistsKey);
    if (rawJson == null) return {};

    final decoded = jsonDecode(rawJson);
    if (decoded is! Map) return {};

    return decoded.map((key, value) {
      return MapEntry(key.toString(), _playlistFromJson(_asMap(value)));
    });
  }
}

Map<String, dynamic> _trackToJson(Track track) {
  return <String, dynamic>{
    'id': track.id,
    'title': track.title,
    'artist': track.artist,
    'audioUrl': track.audioUrl,
    'artworkUrl': track.artworkUrl,
    'handle': track.handle,
    'artistId': track.artistId,
    'likesCount': track.likesCount,
    'repostsCount': track.repostsCount,
    'durationMs': track.durationMs,
    'localPath': track.localPath,
  };
}

Track _trackFromJson(Map<String, dynamic> json) {
  return Track(
    id: _asString(json['id'] ?? json['trackId'] ?? json['track_id']),
    title: _asString(json['title'], fallback: 'Untitled'),
    artist: _asString(json['artistName'] ?? json['artist'],
        fallback: 'Unknown artist'),
    audioUrl: _asString(json['audioUrl'] ?? json['streamUrl']),
    artworkUrl: _asNullableString(
      json['artworkUrl'] ?? json['coverArtUrl'] ?? json['cover_art_url'],
    ),
    handle: _asNullableString(json['handle'] ?? json['artistHandle']),
    artistId: _asNullableString(json['artistId'] ?? json['artist_id']),
    likesCount: _asInt(json['likesCount']),
    repostsCount: _asInt(json['repostsCount']),
    durationMs: _asNullableInt(json['durationMs']),
    localPath: _asNullableString(json['localPath']),
  );
}

Map<String, dynamic> _playlistToJson(PlaylistEntity playlist) {
  return <String, dynamic>{
    'playlistId': playlist.playlistId,
    'title': playlist.title,
    'description': playlist.description,
    'visibility': playlist.visibility.apiValue,
    'genre': playlist.genre,
    'genreId': playlist.genreId,
    'slug': playlist.slug,
    'playlistType': playlist.playlistType,
    'releaseDate': playlist.releaseDate?.toIso8601String(),
    'tags': playlist.tags,
    'secretToken': playlist.secretToken,
    'coverImageUrl': playlist.coverImageUrl,
    'owner': playlist.owner == null
        ? null
        : <String, dynamic>{
            'id': playlist.owner!.id,
            'displayName': playlist.owner!.displayName,
          },
    'tracks': playlist.tracks.map(_trackToJson).toList(growable: false),
    'tracksCount': playlist.tracksCount,
    'likesCount': playlist.likesCount,
    'isLiked': playlist.isLiked,
  };
}

PlaylistEntity _playlistFromJson(Map<String, dynamic> json) {
  final ownerMap = _asMap(json['owner']);
  final tracksRaw = json['tracks'];
  final tracks = tracksRaw is List
      ? tracksRaw
          .map((value) => _trackFromJson(_asMap(value)))
          .where((track) => track.id.isNotEmpty)
          .toList(growable: false)
      : const <Track>[];

  return PlaylistEntity(
    playlistId: _asString(json['playlistId']),
    title: _asString(json['title'], fallback: 'Untitled playlist'),
    description: _asString(json['description']),
    visibility: playlistVisibilityFromApi(_asString(json['visibility'])),
    genre: _asNullableString(json['genre']),
    genreId: _asNullableInt(json['genreId']),
    slug: _asNullableString(json['slug']),
    playlistType: _asString(json['playlistType'], fallback: 'PLAYLIST'),
    releaseDate: _asDate(json['releaseDate']),
    tags: _asStringList(json['tags']),
    secretToken: _asNullableString(json['secretToken']),
    coverImageUrl: _asNullableString(json['coverImageUrl']),
    owner: ownerMap.isEmpty
        ? null
        : PlaylistOwner(
            id: _asString(ownerMap['id']),
            displayName: _asString(ownerMap['displayName']),
          ),
    tracks: tracks,
    tracksCount: _asNullableInt(json['tracksCount']) ?? tracks.length,
    likesCount: _asInt(json['likesCount']),
    isLiked: json['isLiked'] == true,
  );
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

dynamic _extractData(dynamic value) {
  final map = _asMap(value);
  if (map.isEmpty) return value;
  return map['data'] ?? map;
}

String _asString(dynamic value, {String fallback = ''}) {
  final parsed = value?.toString().trim() ?? '';
  return parsed.isEmpty ? fallback : parsed;
}

String? _asNullableString(dynamic value) {
  final parsed = _asString(value);
  return parsed.isEmpty ? null : parsed;
}

int _asInt(dynamic value) => _asNullableInt(value) ?? 0;

int? _asNullableInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

DateTime? _asDate(dynamic value) {
  if (value is DateTime) return value;
  final parsed = value?.toString().trim() ?? '';
  if (parsed.isEmpty) return null;
  return DateTime.tryParse(parsed);
}

List<String> _asStringList(dynamic value) {
  if (value is! List) return const <String>[];
  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}
