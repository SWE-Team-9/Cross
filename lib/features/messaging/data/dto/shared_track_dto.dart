import '../../domain/entities/shared_track_entity.dart';

class SharedTrackDto {
  final String id;
  final String title;
  final String artist;
  final String? artworkUrl;
  final String? handle;
  final String? slug;

  const SharedTrackDto({
    required this.id,
    required this.title,
    required this.artist,
    required this.artworkUrl,
    this.handle,
    this.slug,
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
      handle: (json['handle'] ?? json['artistHandle'] ?? json['artist_handle'])
          ?.toString(),
      slug: (json['slug'] ?? json['trackSlug'] ?? json['track_slug'])
          ?.toString(),
    );
  }

  SharedTrackEntity toEntity() {
    return SharedTrackEntity(
      id: id,
      title: title,
      artist: artist,
      artworkUrl: artworkUrl,
      handle: handle,
      slug: slug,
    );
  }
}
