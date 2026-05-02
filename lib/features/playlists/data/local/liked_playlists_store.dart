import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';

class LikedPlaylistsStore {
  static const _key = 'liked_playlists_local';

  const LikedPlaylistsStore();

  Future<List<PlaylistEntity>> load({int limit = 100}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_key);
      if (rawJson == null) return const <PlaylistEntity>[];

      final decoded = jsonDecode(rawJson);
      if (decoded is! List) return const <PlaylistEntity>[];

      return decoded
          .map((value) => _playlistFromJson(_asMap(value)))
          .where((playlist) => playlist.playlistId.isNotEmpty)
          .take(limit)
          .toList(growable: false);
    } catch (_) {
      return const <PlaylistEntity>[];
    }
  }

  Future<bool> isLiked(String playlistId) async {
    final playlists = await load();
    return playlists.any((playlist) => playlist.playlistId == playlistId);
  }

  Future<void> saveLiked(PlaylistEntity playlist, {int limit = 100}) async {
    final current = await load(limit: limit);
    final liked = playlist.copyWith(
      isLiked: true,
      likesCount:
          playlist.isLiked ? playlist.likesCount : playlist.likesCount + 1,
    );
    final updated = <PlaylistEntity>[
      liked,
      ...current.where((item) => item.playlistId != playlist.playlistId),
    ];
    await _save(updated.take(limit).toList(growable: false));
  }

  Future<void> remove(String playlistId) async {
    final current = await load();
    await _save(
      current
          .where((playlist) => playlist.playlistId != playlistId)
          .toList(growable: false),
    );
  }

  Future<void> _save(List<PlaylistEntity> playlists) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(playlists.map(_playlistToJson).toList(growable: false)),
      );
    } catch (_) {
      // local liked playlist cache is a UI fallback
    }
  }
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
  final rawTracks = json['tracks'];
  final tracks = rawTracks is List
      ? rawTracks
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
    isLiked: json['isLiked'] != false,
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
    id: _asString(json['id']),
    title: _asString(json['title'], fallback: 'Untitled'),
    artist: _asString(json['artist'], fallback: 'Unknown artist'),
    audioUrl: _asString(json['audioUrl']),
    artworkUrl: _asNullableString(json['artworkUrl']),
    handle: _asNullableString(json['handle']),
    artistId: _asNullableString(json['artistId']),
    likesCount: _asInt(json['likesCount']),
    repostsCount: _asInt(json['repostsCount']),
    durationMs: _asNullableInt(json['durationMs']),
    localPath: _asNullableString(json['localPath']),
  );
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
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
