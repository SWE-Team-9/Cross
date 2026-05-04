// lib/features/discovery/domain/entities/trending_track.dart

class TrendingTrack {
  final String id;
  final String title;
  final String genre;
  final String audioUrl;
  final String coverUrl;
  final double trendingScore;
  final int playCount;
  final int likesCount;
  final int repostsCount;
  final int commentsCount;
  final bool isLiked;
  final String ownerHandle;
  final String ownerDisplayName;
  final String ownerId;
  final String slug;

  const TrendingTrack({
    required this.id,
    required this.title,
    required this.genre,
    required this.audioUrl,
    required this.coverUrl,
    required this.trendingScore,
    required this.playCount,
    required this.likesCount,
    required this.repostsCount,
    this.commentsCount = 0,
    this.isLiked = false,
    required this.ownerHandle,
    required this.ownerDisplayName,
    required this.ownerId,
    this.slug = '',
  });
}
