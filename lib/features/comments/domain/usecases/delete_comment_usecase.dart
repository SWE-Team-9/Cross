import '../repositories/comments_repository.dart';

class DeleteCommentUseCase {
  final CommentsRepository repository;

  DeleteCommentUseCase(this.repository);

  Future<void> call(String commentId) {
    return repository.deleteComment(commentId);
  }
}
