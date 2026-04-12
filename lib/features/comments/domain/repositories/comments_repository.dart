import '../entities/comment_entity.dart';

abstract class CommentsRepository {
  Future<List<CommentEntity>> getTrackComments(String trackId);

  Future<CommentEntity> createComment({
    required String trackId,
    required String content,
    String? parentCommentId,
    int? timestampSeconds,
  });

  Future<void> deleteComment(String commentId);
}
