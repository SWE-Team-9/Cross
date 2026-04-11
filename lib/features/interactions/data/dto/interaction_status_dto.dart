import '../../domain/entities/interaction_status.dart';

class InteractionStatusDto {
  final bool isLiked;
  final bool isReposted;
  final int likesCount;
  final int repostsCount;

  const InteractionStatusDto({
    required this.isLiked,
    required this.isReposted,
    required this.likesCount,
    required this.repostsCount,
  });

  factory InteractionStatusDto.fromJson(Map<String, dynamic> json) {
    return InteractionStatusDto(
      isLiked: json['is_liked'] ?? json['liked'] ?? false,
      isReposted: json['is_reposted'] ?? json['reposted'] ?? false,
      likesCount: _toInt(json['likes_count'] ?? json['like_count']),
      repostsCount: _toInt(json['reposts_count'] ?? json['repost_count']),
    );
  }

  InteractionStatus toEntity() {
    return InteractionStatus(
      isLiked: isLiked,
      isReposted: isReposted,
      likesCount: likesCount,
      repostsCount: repostsCount,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}