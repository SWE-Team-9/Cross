class SharedTrackEntity {
  final String id;
  final String title;
  final String artist;
  final String? artworkUrl;
  final String? handle;
  final String? slug;

  const SharedTrackEntity({
    required this.id,
    required this.title,
    required this.artist,
    required this.artworkUrl,
    this.handle,
    this.slug,
  });
}
