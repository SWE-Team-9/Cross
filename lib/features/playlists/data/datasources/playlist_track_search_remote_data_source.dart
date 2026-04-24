import 'dart:convert';

import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/network/api_constants.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';

class PlaylistTrackSearchRemoteDataSource {
  final DioClient dioClient;

  PlaylistTrackSearchRemoteDataSource(this.dioClient);

  Future<List<Track>> searchTracks(
    String query, {
    int limit = 25,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const <Track>[];

    final primary = await _searchWith(
      {
        'q': trimmed,
        'limit': limit,
      },
    );

    if (primary.isNotEmpty) {
      return primary;
    }

    return _searchWith(
      {
        'query': trimmed,
        'limit': limit,
      },
    );
  }

  Future<List<Track>> _searchWith(Map<String, dynamic> params) async {
    final response = await dioClient.get(
      ApiConstants.tracks,
      queryParameters: params,
    );

    final payload = _decode(response.data);
    final list = _extractTrackList(payload);

    final tracks = list
        .map((item) => _parseTrack(_asMap(item)))
        .whereType<Track>()
        .toList(growable: false);

    final deduped = <String, Track>{};
    for (final track in tracks) {
      if (track.id.trim().isEmpty) continue;
      deduped[track.id] = track;
    }

    return deduped.values.toList(growable: false);
  }

  dynamic _decode(dynamic data) {
    if (data is String) return jsonDecode(data);
    return data;
  }

  List<dynamic> _extractTrackList(dynamic payload) {
    if (payload is List) return payload;

    if (payload is Map<String, dynamic>) {
      final data = payload['data'];

      if (data is List) return data;
      if (data is Map<String, dynamic>) {
        final nested = data['tracks'] ?? data['items'] ?? data['results'];
        if (nested is List) return nested;
      }

      final direct =
          payload['tracks'] ?? payload['items'] ?? payload['results'];
      if (direct is List) return direct;
    }

    return const <dynamic>[];
  }

  Track? _parseTrack(Map<String, dynamic> json) {
    final id = _asString(json['trackId'] ?? json['id'] ?? json['_id']);
    if (id.isEmpty) return null;

    final uploader =
        _asMap(json['uploader'] ?? json['artist'] ?? json['owner']);

    final title = _asString(json['title'], fallback: 'Untitled');
    final artist = _asString(
      json['artistName'] ??
          json['artist'] ??
          uploader['display_name'] ??
          uploader['displayName'] ??
          uploader['username'],
      fallback: 'Unknown artist',
    );

    return Track(
      id: id,
      title: title,
      artist: artist,
      audioUrl: _asString(json['audioUrl'] ?? json['streamUrl']),
      artworkUrl: _nullable(_asString(
        json['coverArtUrl'] ??
            json['cover_art_url'] ??
            json['artworkUrl'] ??
            json['artwork_url'],
      )),
      handle: _nullable(_asString(
        json['artistHandle'] ?? uploader['handle'] ?? uploader['username'],
      )),
      artistId: _nullable(_asString(
        json['artistId'] ??
            json['artist_id'] ??
            uploader['id'] ??
            uploader['userId'] ??
            uploader['user_id'],
      )),
      likesCount: _asInt(json['likesCount'] ?? json['likes_count']) ?? 0,
      repostsCount: _asInt(json['repostsCount'] ?? json['reposts_count']) ?? 0,
      durationMs: _asInt(json['durationMs'] ?? json['duration_ms']),
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

  String? _nullable(String value) {
    final parsed = value.trim();
    return parsed.isEmpty ? null : parsed;
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
