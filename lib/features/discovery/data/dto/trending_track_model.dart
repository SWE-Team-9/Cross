// lib/features/discovery/data/dto/trending_track_model.dart

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
  });

  factory TrendingTrackModel.fromJson(Map<String, dynamic> json) {
    final uploader = json['uploader'] as Map<String, dynamic>? ?? {};

    return TrendingTrackModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      genre: json['genre'] as String? ?? '',
      audioUrl: json['audioUrl'] as String? ?? json['audio_url'] as String? ?? '',
      coverUrl: json['coverArtUrl'] as String? ?? json['cover_url'] as String? ?? '',
      trendingScore: (json['velocityScore'] as num?)?.toDouble() ??
          (json['trending_score'] as num?)?.toDouble() ?? 0.0,
      playCount: json['recentPlays'] as int? ?? 0,
      likesCount: json['recentLikes'] as int? ?? 0,
      repostsCount: 0,
      commentsCount: json['commentsCount'] as int? ?? 0,
      isLiked: json['liked'] as bool? ?? false,
      ownerHandle: uploader['handle'] as String? ?? '',
      ownerDisplayName: uploader['displayName'] as String? ?? '',
      ownerId: uploader['userId'] as String? ?? json['uploaderId'] as String? ?? '',
    );
  }
}