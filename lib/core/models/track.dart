class Track {
  final String id;
  final String title;
  final String artist;
  final String audioUrl;
  final String? artworkUrl;
  final String? handle;
  final String? slug;
  final String? artistId;
  final String? genre;
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
    this.genre,
    this.likesCount = 0,
    this.repostsCount = 0,
    this.durationMs,
    this.localPath,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    final artistJson = json['artist'] as Map<String, dynamic>?;
    final uploaderJson = json['uploader'] as Map<String, dynamic>?;
    final uploaderProfile = uploaderJson?['profile'] as Map<String, dynamic>?;
    final genreJson = json['genre'] as Map<String, dynamic>?;

    return Track(
      id: _s(json['id'] ?? json['trackId']),
      title: _s(json['title']),
      artist: _s(
        json['artist'] is String ? json['artist'] : null,
        fallback: _s(
          artistJson?['displayName'] ??
              artistJson?['handle'] ??
              uploaderProfile?['displayName'] ??
              uploaderProfile?['handle'] ??
              json['artistName'] ??
              json['artistHandle'],
        ),
      ),
      audioUrl: _s(json['audio_url'] ?? json['audioUrl'] ?? json['streamUrl']),
      artworkUrl: _nullableString(
        json['artwork_url'] ?? json['artworkUrl'] ?? json['coverArtUrl'],
      ),
      handle: _nullableString(
        json['handle'] ??
            json['artistHandle'] ??
            artistJson?['handle'] ??
            uploaderProfile?['handle'],
      ),
      slug: _nullableString(json['slug']),
      artistId: _nullableString(
        json['artist_id'] ??
            json['artistId'] ??
            json['uploaderId'] ??
            artistJson?['id'] ??
            uploaderJson?['userId'],
      ),
      genre: _nullableString(
        genreJson?['slug'] ?? genreJson?['name'] ?? json['genre'],
      ),
      likesCount: _int(json['likes_count'] ?? json['likesCount']),
      repostsCount: _int(json['reposts_count'] ?? json['repostsCount']),
      durationMs: _nullableInt(json['duration_ms'] ?? json['durationMs']),
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
    String? genre,
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
      genre: genre ?? this.genre,
      likesCount: likesCount ?? this.likesCount,
      repostsCount: repostsCount ?? this.repostsCount,
      durationMs: durationMs ?? this.durationMs,
      localPath: localPath ?? this.localPath,
    );
  }

  static String _s(dynamic value, {String fallback = ''}) {
    final text = value?.toString() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static int _int(dynamic value) {
    return _nullableInt(value) ?? 0;
  }

  static int? _nullableInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
