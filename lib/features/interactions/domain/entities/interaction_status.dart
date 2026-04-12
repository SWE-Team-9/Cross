class InteractionStatus {
  final bool isLiked;
  final bool isReposted;
  final int likesCount;
  final int repostsCount;

  const InteractionStatus({
    required this.isLiked,
    required this.isReposted,
    required this.likesCount,
    required this.repostsCount,
  });
}
