import '../../domain/entities/interaction_status.dart';

class InteractionStatusDto {
  final bool isLiked;
  final bool isReposted;

  const InteractionStatusDto({
    required this.isLiked,
    required this.isReposted,
  });

  factory InteractionStatusDto.fromJson(Map<String, dynamic> json) {
    return InteractionStatusDto(
      isLiked: json['isLiked'] ?? json['is_liked'] ?? json['liked'] ?? false,
      isReposted: json['isReposted'] ??
          json['is_reposted'] ??
          json['reposted'] ??
          false,
    );
  }

  InteractionStatus toEntity() {
    return InteractionStatus(
      isLiked: isLiked,
      isReposted: isReposted,
    );
  }
}
