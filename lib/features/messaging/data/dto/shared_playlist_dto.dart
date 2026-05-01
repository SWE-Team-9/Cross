import '../../domain/entities/shared_playlist_entity.dart';

class SharedPlaylistDto {
  final String id;
  final String title;
  final int tracksCount;
  final String? artworkUrl;

  const SharedPlaylistDto({
    required this.id,
    required this.title,
    required this.tracksCount,
    required this.artworkUrl,
  });

  factory SharedPlaylistDto.fromJson(Map<String, dynamic> json) {
    return SharedPlaylistDto(
      id: (json['id'] ?? json['playlistId'] ?? json['playlist_id'] ?? '')
          .toString(),
      title: (json['title'] ?? '').toString(),
      tracksCount: _toInt(
            json['tracksCount'] ?? json['tracks_count'] ?? json['count'],
          ) ??
          0,
      artworkUrl: (json['artworkUrl'] ??
              json['artwork_url'] ??
              json['coverArtUrl'] ??
              json['cover_art_url'] ??
              json['coverUrl'] ??
              json['cover_url'])
          ?.toString(),
    );
  }

  SharedPlaylistEntity toEntity() {
    return SharedPlaylistEntity(
      id: id,
      title: title,
      tracksCount: tracksCount,
      artworkUrl: artworkUrl,
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString());
  }
}
