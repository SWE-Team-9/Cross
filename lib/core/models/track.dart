class Track {
  final String id;
  final String title;
  final String artist;
  final String audioUrl;
  final String? artworkUrl;
  final String? handle;
  final int likesCount;
  final int repostsCount;
  final int? durationMs;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioUrl,
    this.artworkUrl,
    this.handle,
    this.likesCount = 0,
    this.repostsCount = 0,
    this.durationMs,
  });

  Duration? get duration {
    final value = durationMs;
    if (value == null || value <= 0) return null;
    return Duration(milliseconds: value);
  }

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? audioUrl,
    String? artworkUrl,
    String? handle,
    int? likesCount,
    int? repostsCount,
    int? durationMs,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      audioUrl: audioUrl ?? this.audioUrl,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      handle: handle ?? this.handle,
      likesCount: likesCount ?? this.likesCount,
      repostsCount: repostsCount ?? this.repostsCount,
      durationMs: durationMs ?? this.durationMs,
    );
  }
}
