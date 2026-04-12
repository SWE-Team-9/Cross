import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/comments/domain/entities/comment_entity.dart';
import 'package:soundcloud_clone/features/comments/domain/repositories/comments_repository.dart';

class MockCommentsRepository extends Mock implements CommentsRepository {}

CommentEntity makeEntityComment(String id) {
  return CommentEntity(
    id: id,
    content: 'comment-$id',
    userId: 'u-$id',
    userDisplayName: 'User $id',
    userAvatarUrl: null,
    parentCommentId: null,
    timestampSeconds: 5,
    createdAt: DateTime(2026, 1, 1),
    replies: const [],
  );
}
