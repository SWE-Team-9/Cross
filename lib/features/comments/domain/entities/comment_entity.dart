class CommentEntity {
  final String id;
  final String content;
  final String userId;
  final String userDisplayName;
  final String? userAvatarUrl;
  final String? parentCommentId;
  final int? timestampSeconds;
  final DateTime? createdAt;
  final List<CommentEntity> replies;

  const CommentEntity({
    required this.id,
    required this.content,
    required this.userId,
    required this.userDisplayName,
    required this.userAvatarUrl,
    required this.parentCommentId,
    required this.timestampSeconds,
    required this.createdAt,
    required this.replies,
  });

  bool get isReply => parentCommentId != null;
}