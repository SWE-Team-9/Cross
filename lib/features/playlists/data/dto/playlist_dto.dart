import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';

class PlaylistDto {
  final String playlistId;
  final String title;
  final String description;
  final PlaylistVisibility visibility;
  final String? secretToken;
  final PlaylistOwner? owner;
  final List<Track> tracks;
  final int tracksCount;

  const PlaylistDto({
    required this.playlistId,
    required this.title,
    required this.description,
    required this.visibility,
    required this.secretToken,
    required this.owner,
    required this.tracks,
    required this.tracksCount,
  });

  factory PlaylistDto.fromJson(Map<String, dynamic> json) {
    final rawTracks = _extractTracksList(json);
    final tracks = rawTracks
        .map((item) => _trackFromJson(_asMap(item)))
        .whereType<Track>()
        .toList(growable: false);

    final ownerMap = _asMap(json['owner']);
    final owner = ownerMap.isEmpty
        ? null
        : PlaylistOwner(
            id: _asString(ownerMap['id'] ?? ownerMap['userId']),
            displayName: _asString(
              ownerMap['display_name'] ??
                  ownerMap['displayName'] ??
                  ownerMap['username'],
            ),
          );

    final trackCount = _asInt(
          json['tracksCount'] ??
              json['tracks_count'] ??
              json['trackCount'] ??
              json['track_count'],
        ) ??
        tracks.length;

    return PlaylistDto(
      playlistId: _asString(json['playlistId'] ?? json['id']),
      title: _asString(json['title'], fallback: 'Untitled playlist'),
      description: _asString(json['description']),
      visibility: playlistVisibilityFromApi(_asString(json['visibility'])),
      secretToken: _normalizeNullable(
        _asString(json['secretToken'] ?? json['secret_token']),
      ),
      owner: owner,
      tracks: tracks,
      tracksCount: trackCount,
    );
  }

  PlaylistEntity toEntity() {
    return PlaylistEntity(
      playlistId: playlistId,
      title: title,
      description: description,
      visibility: visibility,
      secretToken: secretToken,
      owner: owner,
      tracks: tracks,
      tracksCount: tracksCount,
    );
  }
}

List<dynamic> _extractTracksList(Map<String, dynamic> json) {
  final direct = json['tracks'];
  if (direct is List) return direct;

  final data = json['data'];
  if (data is Map<String, dynamic>) {
    final nested = data['tracks'];
    if (nested is List) return nested;
  }

  return const <dynamic>[];
}

Track? _trackFromJson(Map<String, dynamic> json) {
  final id = _asString(
    json['trackId'] ?? json['id'] ?? json['_id'],
  );
  if (id.isEmpty) return null;

  final uploaderMap =
      _asMap(json['uploader'] ?? json['owner'] ?? json['artist']);

  final title = _asString(json['title'], fallback: 'Untitled');
  final artist = _asString(
    json['artistName'] ??
        json['artist'] ??
        uploaderMap['display_name'] ??
        uploaderMap['displayName'] ??
        uploaderMap['username'],
    fallback: 'Unknown artist',
  );

  final handle = _normalizeNullable(
    _asString(
      json['artistHandle'] ?? uploaderMap['handle'] ?? uploaderMap['username'],
    ),
  );

  final artistId = _normalizeNullable(
    _asString(
      json['artistId'] ??
          json['artist_id'] ??
          uploaderMap['id'] ??
          uploaderMap['userId'],
    ),
  );

  return Track(
    id: id,
    title: title,
    artist: artist,
    audioUrl: _asString(json['audioUrl'] ?? json['streamUrl']),
    artworkUrl: _normalizeNullable(
      _asString(
        json['coverArtUrl'] ??
            json['cover_art_url'] ??
            json['artworkUrl'] ??
            json['artwork_url'],
      ),
    ),
    handle: handle,
    artistId: artistId,
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

String? _normalizeNullable(String value) {
  return value.trim().isEmpty ? null : value.trim();
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
