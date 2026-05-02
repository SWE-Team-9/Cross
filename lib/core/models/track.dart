class Track {
  final String id;
  final String title;
  final String artist;
  final String audioUrl;
  final String? artworkUrl;
  final String? handle;
  final String? slug;
  final String? artistId;
  final int likesCount;
  final int repostsCount;
  final int? durationMs;
  final String? localPath;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioUrl,
    this.artworkUrl,
    this.handle,
    this.slug,
    this.artistId,
    this.likesCount = 0,
    this.repostsCount = 0,
    this.durationMs,
    this.localPath,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      audioUrl: json['audio_url'] as String? ?? '',
      artworkUrl: json['artwork_url'] as String?,
      handle: json['handle'] as String? ?? json['artistHandle'] as String?,
      slug: json['slug'] as String?,
      artistId: json['artist_id'] as String? ?? json['artistId'] as String?,
      likesCount:
          json['likes_count'] as int? ?? json['likesCount'] as int? ?? 0,
      repostsCount:
          json['reposts_count'] as int? ?? json['repostsCount'] as int? ?? 0,
      durationMs: json['duration_ms'] as int? ?? json['durationMs'] as int?,
    );
  }

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
    String? slug,
    String? artistId,
    String? localPath,
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
      slug: slug ?? this.slug,
      artistId: artistId ?? this.artistId,
      likesCount: likesCount ?? this.likesCount,
      repostsCount: repostsCount ?? this.repostsCount,
      durationMs: durationMs ?? this.durationMs,
      localPath: localPath ?? this.localPath,
    );
  }
}
