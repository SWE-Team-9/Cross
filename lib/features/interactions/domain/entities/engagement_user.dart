class EngagementUser {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final DateTime? interactedAt;

  const EngagementUser({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.interactedAt,
  });
}