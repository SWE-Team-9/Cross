import '../../domain/entities/shared_track_entity.dart';

class SharedTrackDto {
  final String id;
  final String title;
  final String artist;
  final String? artworkUrl;

  const SharedTrackDto({
    required this.id,
    required this.title,
    required this.artist,
    required this.artworkUrl,
  });

  factory SharedTrackDto.fromJson(Map<String, dynamic> json) {
    return SharedTrackDto(
      id: (json['id'] ?? json['trackId'] ?? json['track_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      artist:
          (json['artist'] ?? json['artistName'] ?? json['artist_name'] ?? '')
              .toString(),
      artworkUrl: (json['artworkUrl'] ??
              json['artwork_url'] ??
              json['coverArtUrl'] ??
              json['cover_art_url'] ??
              json['coverUrl'] ??
              json['cover_url'])
          ?.toString(),
    );
  }

  SharedTrackEntity toEntity() {
    return SharedTrackEntity(
      id: id,
      title: title,
      artist: artist,
      artworkUrl: artworkUrl,
    );
  }
}
