import '../../domain/entities/comment_entity.dart';

class CommentDto {
  final String id;
  final String content;
  final String userId;
  final String userDisplayName;
  final String? userAvatarUrl;
  final String? parentCommentId;
  final int? timestampSeconds;
  final DateTime? createdAt;
  final List<CommentDto> replies;

  const CommentDto({
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

  factory CommentDto.fromJson(Map<String, dynamic> json) {
    final rawReplies = (json['replies'] as List?) ?? const [];

    return CommentDto(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      content: (json['content'] ?? json['text'] ?? '').toString(),
      userId: (json['user_id'] ?? json['userId'] ?? json['user']?['id'] ?? '')
          .toString(),
      userDisplayName: (json['user']?['display_name'] ??
              json['user']?['username'] ??
              json['author_name'] ??
              'Unknown')
          .toString(),
      userAvatarUrl: json['user']?['avatar_url']?.toString(),
      parentCommentId: json['parent_comment_id']?.toString(),
      timestampSeconds: json['timestamp_seconds'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      replies: rawReplies
          .map((e) => CommentDto.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
    );
  }

  CommentEntity toEntity() {
    return CommentEntity(
      id: id,
      content: content,
      userId: userId,
      userDisplayName: userDisplayName,
      userAvatarUrl: userAvatarUrl,
      parentCommentId: parentCommentId,
      timestampSeconds: timestampSeconds,
      createdAt: createdAt,
      replies: replies.map((e) => e.toEntity()).toList(growable: false),
    );
  }
}
