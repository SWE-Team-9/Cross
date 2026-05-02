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

    final userMap = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : <String, dynamic>{};

    return CommentDto(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      content: (json['content'] ?? json['text'] ?? '').toString(),
      userId: (json['user_id'] ??
              json['userId'] ??
              userMap['userId'] ??
              userMap['id'] ??
              '')
          .toString(),
      userDisplayName: (userMap['displayName'] ??
              userMap['display_name'] ??
              userMap['username'] ??
              userMap['name'] ??
              json['author_name'] ??
              'Unknown User')
          .toString(),
      userAvatarUrl:
          (userMap['avatarUrl'] ?? userMap['avatar_url'])?.toString(),
      parentCommentId:
          (json['parentCommentId'] ?? json['parent_comment_id'])?.toString(),
      timestampSeconds: _toInt(
        json['timestampAt'] ??
            json['timestamp_seconds'] ??
            json['timestampSeconds'],
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : json['created_at'] != null
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

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
