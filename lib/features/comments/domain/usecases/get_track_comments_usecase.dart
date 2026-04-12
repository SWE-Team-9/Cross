import '../entities/comment_entity.dart';
import '../repositories/comments_repository.dart';

class GetTrackCommentsUseCase {
  final CommentsRepository repository;

  GetTrackCommentsUseCase(this.repository);

  Future<List<CommentEntity>> call(String trackId) {
    return repository.getTrackComments(trackId);
  }
}
