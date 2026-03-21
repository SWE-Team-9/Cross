class Track {
  final String id;
  final String title;
  final String artist;
  final String audioUrl;
  final String? artworkUrl;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioUrl,
    this.artworkUrl,
  });
}
