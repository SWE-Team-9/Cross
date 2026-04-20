import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/comments/domain/entities/comment_entity.dart';
import 'package:soundcloud_clone/features/comments/domain/usecases/create_comment_usecase.dart';
import 'package:soundcloud_clone/features/comments/domain/usecases/delete_comment_usecase.dart';
import 'package:soundcloud_clone/features/comments/domain/usecases/get_track_comments_usecase.dart';
import 'package:soundcloud_clone/features/comments/domain/usecases/reply_to_comment_usecase.dart';
import 'package:soundcloud_clone/features/comments/presentation/bloc/comments_cubit.dart';
import 'package:soundcloud_clone/features/comments/presentation/bloc/comments_state.dart';

class MockGetTrackCommentsUseCase extends Mock
    implements GetTrackCommentsUseCase {}

class MockCreateCommentUseCase extends Mock implements CreateCommentUseCase {}

class MockDeleteCommentUseCase extends Mock implements DeleteCommentUseCase {}

class MockReplyToCommentUseCase extends Mock implements ReplyToCommentUseCase {}

CommentEntity makeComment({
  required String id,
  String? parentCommentId,
  List<CommentEntity> replies = const [],
}) {
  return CommentEntity(
    id: id,
    content: 'content-$id',
    userId: 'u-$id',
    userDisplayName: 'User $id',
    userAvatarUrl: null,
    parentCommentId: parentCommentId,
    timestampSeconds: 10,
    createdAt: DateTime(2026, 1, 1),
    replies: replies,
  );
}

void main() {
  late MockGetTrackCommentsUseCase getTrackCommentsUseCase;
  late MockCreateCommentUseCase createCommentUseCase;
  late MockDeleteCommentUseCase deleteCommentUseCase;
  late MockReplyToCommentUseCase replyToCommentUseCase;

  setUp(() {
    getTrackCommentsUseCase = MockGetTrackCommentsUseCase();
    createCommentUseCase = MockCreateCommentUseCase();
    deleteCommentUseCase = MockDeleteCommentUseCase();
    replyToCommentUseCase = MockReplyToCommentUseCase();
  });

  CommentsCubit buildCubit() => CommentsCubit(
        getTrackCommentsUseCase: getTrackCommentsUseCase,
        createCommentUseCase: createCommentUseCase,
        deleteCommentUseCase: deleteCommentUseCase,
        replyToCommentUseCase: replyToCommentUseCase,
      );

  group('CommentsCubit', () {
    test('initial state is CommentsState.initial()', () {
      expect(buildCubit().state.isLoading, isFalse);
      expect(buildCubit().state.isSubmitting, isFalse);
      expect(buildCubit().state.comments, isEmpty);
      expect(buildCubit().state.errorMessage, isNull);
    });

    blocTest<CommentsCubit, CommentsState>(
      'load emits loading then loaded comments',
      build: () {
        when(() => getTrackCommentsUseCase('t1'))
            .thenAnswer((_) async => [makeComment(id: 'c1')]);
        return buildCubit();
      },
      act: (cubit) => cubit.load('t1'),
      expect: () => [
        isA<CommentsState>()
            .having((s) => s.isLoading, 'isLoading', isTrue)
            .having((s) => s.errorMessage, 'errorMessage', isNull),
        isA<CommentsState>()
            .having((s) => s.isLoading, 'isLoading', isFalse)
            .having((s) => s.comments.length, 'comments length', 1),
      ],
    );

    blocTest<CommentsCubit, CommentsState>(
      'load emits error state on exception',
      build: () {
        when(() => getTrackCommentsUseCase('t1')).thenThrow(Exception('boom'));
        return buildCubit();
      },
      act: (cubit) => cubit.load('t1'),
      expect: () => [
        isA<CommentsState>().having((s) => s.isLoading, 'isLoading', isTrue),
        isA<CommentsState>()
            .having((s) => s.isLoading, 'isLoading', isFalse)
            .having((s) => s.errorMessage, 'errorMessage', contains('boom')),
      ],
    );

    blocTest<CommentsCubit, CommentsState>(
      'addComment prepends newly created comment',
      build: () {
        when(
          () => createCommentUseCase(
            trackId: 't1',
            content: 'new',
            timestampSeconds: 20,
          ),
        ).thenAnswer((_) async => makeComment(id: 'new'));
        return buildCubit();
      },
      seed: () => CommentsState.initial().copyWith(
        comments: [makeComment(id: 'old')],
      ),
      act: (cubit) => cubit.addComment(
        trackId: 't1',
        content: 'new',
        timestampSeconds: 20,
      ),
      expect: () => [
        isA<CommentsState>()
            .having((s) => s.isSubmitting, 'isSubmitting', isTrue),
        isA<CommentsState>()
            .having((s) => s.isSubmitting, 'isSubmitting', isFalse)
            .having((s) => s.comments.first.id, 'first id', 'new')
            .having((s) => s.comments.length, 'comments length', 2),
      ],
    );

    blocTest<CommentsCubit, CommentsState>(
      'replyToComment attaches reply under parent',
      build: () {
        when(
          () => replyToCommentUseCase(
            trackId: 't1',
            parentCommentId: 'parent',
            content: 'reply',
            timestampSeconds: 30,
          ),
        ).thenAnswer(
            (_) async => makeComment(id: 'r1', parentCommentId: 'parent'));
        return buildCubit();
      },
      seed: () => CommentsState.initial().copyWith(
        comments: [makeComment(id: 'parent')],
      ),
      act: (cubit) => cubit.replyToComment(
        trackId: 't1',
        parentCommentId: 'parent',
        content: 'reply',
        timestampSeconds: 30,
      ),
      expect: () => [
        isA<CommentsState>()
            .having((s) => s.isSubmitting, 'isSubmitting', isTrue),
        isA<CommentsState>()
            .having((s) => s.isSubmitting, 'isSubmitting', isFalse)
            .having((s) => s.comments.first.replies.length, 'replies length', 1)
            .having((s) => s.comments.first.replies.first.id, 'reply id', 'r1'),
      ],
    );

    blocTest<CommentsCubit, CommentsState>(
      'deleteComment removes matching comment and nested replies',
      build: () {
        when(() => deleteCommentUseCase('c2')).thenAnswer((_) async {});
        return buildCubit();
      },
      seed: () => CommentsState.initial().copyWith(
        comments: [
          makeComment(
            id: 'c1',
            replies: [makeComment(id: 'c2', parentCommentId: 'c1')],
          ),
          makeComment(id: 'c2'),
        ],
      ),
      act: (cubit) => cubit.deleteComment('c2'),
      expect: () => [
        isA<CommentsState>()
            .having((s) => s.comments.length, 'comments length', 1)
            .having((s) => s.comments.first.replies, 'replies', isEmpty),
      ],
      verify: (_) {
        verify(() => deleteCommentUseCase('c2')).called(1);
      },
    );
  });
}
