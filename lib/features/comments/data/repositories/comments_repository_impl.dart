import '../../domain/entities/comment_entity.dart';
import '../../domain/repositories/comments_repository.dart';
import '../datasources/comments_remote_data_source.dart';

class CommentsRepositoryImpl implements CommentsRepository {
  final CommentsRemoteDataSource remoteDataSource;

  CommentsRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<CommentEntity>> getTrackComments(String trackId) async {
    final result = await remoteDataSource.getTrackComments(trackId);
    return result.map((e) => e.toEntity()).toList(growable: false);
  }

  @override
  Future<CommentEntity> createComment({
    required String trackId,
    required String content,
    String? parentCommentId,
    int? timestampSeconds,
  }) async {
    final dto = await remoteDataSource.createComment(
      trackId: trackId,
      content: content,
      parentCommentId: parentCommentId,
      timestampSeconds: timestampSeconds,
    );
    return dto.toEntity();
  }

  @override
  Future<void> deleteComment(String commentId) {
    return remoteDataSource.deleteComment(commentId);
  }
}