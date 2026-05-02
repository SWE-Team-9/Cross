import '../entities/comment_entity.dart';
import '../repositories/comments_repository.dart';

class ReplyToCommentUseCase {
  final CommentsRepository repository;

  ReplyToCommentUseCase(this.repository);

  Future<CommentEntity> call({
    required String trackId,
    required String parentCommentId,
    required String content,
    int? timestampSeconds,
  }) {
    return repository.createComment(
      trackId: trackId,
      content: content,
      parentCommentId: parentCommentId,
      timestampSeconds: timestampSeconds,
    );
  }
}
