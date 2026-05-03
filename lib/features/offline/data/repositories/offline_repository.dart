import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/network/api_constants.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/offline_track_entitlement.dart';

class OfflineRepository {
  static const _tracksKey = 'offline_tracks';
  static const _trackDetailsKey = 'offline_track_details';
  static const _playlistsKey = 'offline_playlists';

  static const _offlineDirectoryName = 'offline';
  static const _offlineTracksDirectoryName = 'tracks';
  static const _audioExtension = '.mp3';

  final DioClient dio;

  OfflineRepository(this.dio);

  // ───────────── DOWNLOAD ─────────────
  Future<String> downloadTrack(String trackId) async {
    final normalizedTrackId = trackId.trim();

    if (normalizedTrackId.isEmpty) {
      throw ArgumentError.value(
          trackId, 'trackId', 'Track id cannot be empty.');
    }

    final entitlementResponse = await dio.get(
      ApiConstants.subscriptionOfflineTrackPath(normalizedTrackId),
    );

    final entitlement = OfflineTrackEntitlement.fromJson(
      _extractPayloadMap(entitlementResponse.data),
    );

    if (!entitlement.isAllowed) {
      throw StateError('Offline downloads require a premium subscription.');
    }

    final response = await dio.get(
      ApiConstants.subscriptionOfflineTrackStreamPath(normalizedTrackId),
      options: Options(responseType: ResponseType.bytes),
    );

    final bytes = _asBytes(response.data);
    if (bytes.isEmpty) {
      throw StateError('Downloaded audio file is empty.');
    }

    final file = await _offlineTrackFile(normalizedTrackId);
    await file.writeAsBytes(bytes, flush: true);

    final downloadedTracks = await getDownloadedTracks();
    downloadedTracks[normalizedTrackId] = file.path;
    await saveDownloadedTracks(downloadedTracks);

    final downloadedTrackDetails = await getDownloadedTrackDetails();
    final existingDetails = await fetchTrackDetails(normalizedTrackId);
    downloadedTrackDetails[normalizedTrackId] = _mergeDownloadedTrackDetails(
      entitlement: entitlement,
      fallbackTrackId: normalizedTrackId,
      localPath: file.path,
      existingDetails: existingDetails,
    );
    await saveDownloadedTrackDetails(downloadedTrackDetails);

    return file.path;
  }

  Future<Track?> fetchTrackDetails(String trackId) async {
    try {
      final response = await dio.get(ApiConstants.trackByIdPath(trackId));
      final data = _extractPayloadMap(response.data);

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
    final rawJson = prefs.getString(_tracksKey);

    if (rawJson == null || rawJson.trim().isEmpty) {
      return <String, String>{};
    }

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map) return <String, String>{};

      return decoded.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    } catch (_) {
      return <String, String>{};
    }
  }

  Future<Map<String, Track>> getDownloadedTrackDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(_trackDetailsKey);

    if (rawJson == null || rawJson.trim().isEmpty) {
      return <String, Track>{};
    }

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map) return <String, Track>{};

      return decoded.map((key, value) {
        return MapEntry(key.toString(), _trackFromJson(_asMap(value)));
      });
    } catch (_) {
      return <String, Track>{};
    }
  }

  Future<Map<String, PlaylistEntity>> getDownloadedPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(_playlistsKey);

    if (rawJson == null || rawJson.trim().isEmpty) {
      return <String, PlaylistEntity>{};
    }

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map) return <String, PlaylistEntity>{};

      return decoded.map((key, value) {
        return MapEntry(key.toString(), _playlistFromJson(_asMap(value)));
      });
    } catch (_) {
      return <String, PlaylistEntity>{};
    }
  }

  Future<File> _offlineTrackFile(String trackId) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final offlineTracksDirectory = Directory(
      '${documentsDirectory.path}/$_offlineDirectoryName/$_offlineTracksDirectoryName',
    );

    if (!offlineTracksDirectory.existsSync()) {
      await offlineTracksDirectory.create(recursive: true);
    }

    return File(
      '${offlineTracksDirectory.path}/${_safeFileName(trackId)}$_audioExtension',
    );
  }
}

Track _mergeDownloadedTrackDetails({
  required OfflineTrackEntitlement entitlement,
  required String fallbackTrackId,
  required String localPath,
  Track? existingDetails,
}) {
  final baseTrack = existingDetails ??
      _trackFromJson(
        <String, dynamic>{
          'id': entitlement.trackId.isEmpty
              ? fallbackTrackId
              : entitlement.trackId,
          'title': entitlement.title,
          'artist': entitlement.artist,
          'handle': entitlement.handle,
          'durationMs': entitlement.durationMs,
          'artworkUrl': entitlement.coverArtUrl,
        },
      );

  return Track(
    id: baseTrack.id.isEmpty ? fallbackTrackId : baseTrack.id,
    title: baseTrack.title,
    artist: baseTrack.artist,
    audioUrl: baseTrack.audioUrl,
    artworkUrl: baseTrack.artworkUrl ?? entitlement.coverArtUrl,
    handle: baseTrack.handle ?? _asNullableString(entitlement.handle),
    artistId: baseTrack.artistId,
    likesCount: baseTrack.likesCount,
    repostsCount: baseTrack.repostsCount,
    durationMs: baseTrack.durationMs ?? entitlement.durationMs,
    localPath: localPath,
  );
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
    artist: _asString(
      json['artistName'] ?? json['artist'],
      fallback: 'Unknown artist',
    ),
    audioUrl: _asString(json['audioUrl'] ?? json['streamUrl']),
    artworkUrl: _asNullableString(
      json['artworkUrl'] ?? json['coverArtUrl'] ?? json['cover_art_url'],
    ),
    handle: _asNullableString(json['handle'] ?? json['artistHandle']),
    artistId: _asNullableString(json['artistId'] ?? json['artist_id']),
    likesCount: _asInt(json['likesCount'] ?? json['likes_count']),
    repostsCount: _asInt(json['repostsCount'] ?? json['reposts_count']),
    durationMs: _asNullableInt(json['durationMs'] ?? json['duration_ms']),
    localPath: _asNullableString(json['localPath'] ?? json['local_path']),
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
    playlistId: _asString(json['playlistId'] ?? json['playlist_id']),
    title: _asString(json['title'], fallback: 'Untitled playlist'),
    description: _asString(json['description']),
    visibility: playlistVisibilityFromApi(_asString(json['visibility'])),
    genre: _asNullableString(json['genre']),
    genreId: _asNullableInt(json['genreId'] ?? json['genre_id']),
    slug: _asNullableString(json['slug']),
    playlistType: _asString(json['playlistType'], fallback: 'PLAYLIST'),
    releaseDate: _asDate(json['releaseDate'] ?? json['release_date']),
    tags: _asStringList(json['tags']),
    secretToken: _asNullableString(json['secretToken'] ?? json['secret_token']),
    coverImageUrl: _asNullableString(
      json['coverImageUrl'] ?? json['cover_image_url'],
    ),
    owner: ownerMap.isEmpty
        ? null
        : PlaylistOwner(
            id: _asString(ownerMap['id']),
            displayName: _asString(ownerMap['displayName']),
          ),
    tracks: tracks,
    tracksCount: _asNullableInt(json['tracksCount'] ?? json['tracks_count']) ??
        tracks.length,
    likesCount: _asInt(json['likesCount'] ?? json['likes_count']),
    isLiked: json['isLiked'] == true || json['is_liked'] == true,
  );
}

dynamic _decodeJsonIfNeeded(dynamic value) {
  if (value is String) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return <String, dynamic>{};
    }

    return jsonDecode(trimmed);
  }

  return value;
}

Map<String, dynamic> _extractPayloadMap(dynamic value) {
  final decoded = _decodeJsonIfNeeded(value);
  final map = _asMap(decoded);

  final data = map['data'];
  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }

  final track = map['track'];
  if (track is Map) {
    return Map<String, dynamic>.from(track);
  }

  final result = map['result'];
  if (result is Map) {
    return Map<String, dynamic>.from(result);
  }

  return map;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<int> _asBytes(dynamic value) {
  if (value is List<int>) {
    return value;
  }

  if (value is List) {
    return value.map((byte) => _asInt(byte).clamp(0, 255)).toList();
  }

  if (value is String) {
    return utf8.encode(value);
  }

  throw StateError('Expected audio bytes but got ${value.runtimeType}.');
}

String _safeFileName(String value) {
  final sanitized = value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  return sanitized.isEmpty ? 'track' : sanitized;
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
