import '../entities/comment_entity.dart';
import '../repositories/comments_repository.dart';

class CreateCommentUseCase {
  final CommentsRepository repository;

  CreateCommentUseCase(this.repository);

  Future<CommentEntity> call({
    required String trackId,
    required String content,
    String? parentCommentId,
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