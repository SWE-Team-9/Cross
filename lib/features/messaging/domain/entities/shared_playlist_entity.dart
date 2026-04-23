class SharedPlaylistEntity {
  final String id;
  final String title;
  final int tracksCount;
  final String? artworkUrl;

  const SharedPlaylistEntity({
    required this.id,
    required this.title,
    required this.tracksCount,
    required this.artworkUrl,
  });
}