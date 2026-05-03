import '../../domain/entities/trending_track.dart';

class TrendingTrackModel extends TrendingTrack {
  const TrendingTrackModel({
    required super.id,
    required super.title,
    required super.genre,
    required super.audioUrl,
    required super.coverUrl,
    required super.trendingScore,
    required super.playCount,
    required super.likesCount,
    required super.repostsCount,
    super.commentsCount = 0,
    super.isLiked = false,
    required super.ownerHandle,
    required super.ownerDisplayName,
    required super.ownerId,
    super.slug = '',
  });

  factory TrendingTrackModel.fromJson(Map<String, dynamic> json) {
    final uploader = _map(json['uploader']);
    final uploaderProfile = _map(uploader['profile']);
    final artist = _map(json['artist']);
    final genreMap = _map(json['genre']);
    final stats = _map(json['stats']);

    return TrendingTrackModel(
      id: _s(json['id'] ?? json['trackId']),
      title: _s(json['title']),
      genre: _s(
        genreMap['slug'] ?? genreMap['name'] ?? json['genre'],
      ),
      audioUrl: _s(
        json['audioUrl'] ?? json['audio_url'] ?? json['streamUrl'],
      ),
      coverUrl: _s(
        json['coverArtUrl'] ??
            json['cover_url'] ??
            json['coverUrl'] ??
            json['artwork_url'],
      ),
      trendingScore: _double(
        json['velocityScore'] ??
            json['trendingScore'] ??
            json['trending_score'],
      ),
      playCount: _int(
        json['recentPlays'] ??
            json['playsCount'] ??
            json['playCount'] ??
            json['views'] ??
            stats['playsCount'],
      ),
      likesCount: _int(
        json['recentLikes'] ?? json['likesCount'] ?? stats['likesCount'],
      ),
      repostsCount: _int(
        json['recentReposts'] ?? json['repostsCount'] ?? stats['repostsCount'],
      ),
      commentsCount: _int(
        json['commentsCount'] ?? stats['commentsCount'],
      ),
      isLiked: json['liked'] as bool? ?? false,
      ownerHandle: _s(
        uploaderProfile['handle'] ??
            uploader['handle'] ??
            artist['handle'] ??
            json['artistHandle'],
      ),
      ownerDisplayName: _s(
        uploaderProfile['displayName'] ??
            uploader['displayName'] ??
            artist['displayName'] ??
            json['artistName'],
      ),
      ownerId: _s(
        uploader['userId'] ??
            uploader['id'] ??
            artist['id'] ??
            json['uploaderId'] ??
            json['artistId'],
      ),
      slug: _s(
        json['slug'] ?? json['trackSlug'] ?? json['track_slug'],
      ),
    );
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  static String _s(dynamic value) => value?.toString() ?? '';

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _double(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}
