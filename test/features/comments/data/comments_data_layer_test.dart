import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/network/api_constants.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/features/comments/data/datasources/comments_remote_data_source.dart';
import 'package:soundcloud_clone/features/comments/data/dto/comment_dto.dart';
import 'package:soundcloud_clone/features/comments/data/repositories/comments_repository_impl.dart';
import 'package:soundcloud_clone/features/comments/domain/entities/comment_entity.dart';
import 'package:soundcloud_clone/features/comments/domain/usecases/create_comment_usecase.dart';
import 'package:soundcloud_clone/features/comments/domain/usecases/delete_comment_usecase.dart';
import 'package:soundcloud_clone/features/comments/domain/usecases/get_track_comments_usecase.dart';
import 'package:soundcloud_clone/features/comments/domain/usecases/reply_to_comment_usecase.dart';

import '../domain/repositories/comments_repository_test_helpers.dart';

class MockDioClient extends Mock implements DioClient {}

class MockCommentsRemoteDataSource extends Mock
    implements CommentsRemoteDataSource {}

void main() {
  group('CommentDto', () {
    test('fromJson handles fallback keys and nested replies', () {
      final dto = CommentDto.fromJson({
        '_id': 'c1',
        'text': 'hello',
        'user': {
          'id': 'u1',
          'username': 'alice',
          'avatar_url': 'https://a.com/1.png',
        },
        'created_at': '2026-01-01T10:00:00.000Z',
        'replies': [
          {
            'id': 'c2',
            'content': 'reply',
            'user_id': 'u2',
            'author_name': 'Bob',
          }
        ],
      });

      expect(dto.id, 'c1');
      expect(dto.content, 'hello');
      expect(dto.userDisplayName, 'alice');
      expect(dto.replies.length, 1);
      expect(dto.replies.first.id, 'c2');
    });

    test('toEntity maps replies recursively and isReply works', () {
      final dto = CommentDto(
        id: 'parent',
        content: 'parent',
        userId: 'u1',
        userDisplayName: 'User',
        userAvatarUrl: null,
        parentCommentId: null,
        timestampSeconds: 10,
        createdAt: DateTime(2026, 1, 1),
        replies: [
          CommentDto(
            id: 'reply',
            content: 'reply',
            userId: 'u2',
            userDisplayName: 'User2',
            userAvatarUrl: null,
            parentCommentId: 'parent',
            timestampSeconds: null,
            createdAt: null,
            replies: const [],
          )
        ],
      );

      final entity = dto.toEntity();

      expect(entity.replies.first.isReply, isTrue);
      expect(entity.replies.first.parentCommentId, 'parent');
    });
  });

  group('CommentsRemoteDataSourceImpl', () {
    late MockDioClient dioClient;
    late CommentsRemoteDataSourceImpl dataSource;

    setUp(() {
      dioClient = MockDioClient();
      dataSource = CommentsRemoteDataSourceImpl(dioClient);
    });

    test('getTrackComments reads comments from map payload', () async {
      when(() => dioClient.get(ApiConstants.trackCommentsPath('t1')))
          .thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {
            'comments': [
              {
                'id': 'c1',
                'content': 'comment',
                'user_id': 'u1',
                'author_name': 'Ali',
              }
            ]
          },
        ),
      );

      final result = await dataSource.getTrackComments('t1');

      expect(result.single.id, 'c1');
      verify(() => dioClient.get(ApiConstants.trackCommentsPath('t1')))
          .called(1);
    });

    test('createComment posts payload and parses response', () async {
      when(
        () => dioClient.post(
          ApiConstants.trackCommentsPath('t1'),
          data: {
            'content': 'hey',
            'timestampAt': 33,
            'parentCommentId': 'p1',
          },
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {
            'comment': {
              'id': 'c3',
              'content': 'hey',
              'user_id': 'u3',
              'author_name': 'Salma',
            }
          },
        ),
      );

      final created = await dataSource.createComment(
        trackId: 't1',
        content: 'hey',
        parentCommentId: 'p1',
        timestampSeconds: 33,
      );

      expect(created.id, 'c3');
      expect(created.content, 'hey');
    });

    test('deleteComment calls delete endpoint', () async {
      when(() => dioClient.delete(ApiConstants.commentByIdPath('c1')))
          .thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {},
        ),
      );

      await dataSource.deleteComment('c1');

      verify(() => dioClient.delete(ApiConstants.commentByIdPath('c1')))
          .called(1);
    });
  });

  group('CommentsRepositoryImpl and usecases', () {
    late MockCommentsRemoteDataSource remote;
    late CommentsRepositoryImpl repository;
    late MockCommentsRepository commentsRepository;

    setUp(() {
      remote = MockCommentsRemoteDataSource();
      repository = CommentsRepositoryImpl(remote);
      commentsRepository = MockCommentsRepository();
    });

    test('repository maps dto list to entities', () async {
      when(() => remote.getTrackComments('t1')).thenAnswer(
        (_) async => [
          const CommentDto(
            id: 'c1',
            content: 'x',
            userId: 'u1',
            userDisplayName: 'Ali',
            userAvatarUrl: null,
            parentCommentId: null,
            timestampSeconds: null,
            createdAt: null,
            replies: [],
          ),
        ],
      );

      final result = await repository.getTrackComments('t1');

      expect(result.single, isA<CommentEntity>());
      expect(result.single.id, 'c1');
    });

    test('repository create/delete delegate and usecases forward', () async {
      when(
        () => remote.createComment(
          trackId: 't1',
          content: 'new',
          parentCommentId: any(named: 'parentCommentId'),
          timestampSeconds: any(named: 'timestampSeconds'),
        ),
      ).thenAnswer(
        (_) async => const CommentDto(
          id: 'c9',
          content: 'new',
          userId: 'u1',
          userDisplayName: 'Ali',
          userAvatarUrl: null,
          parentCommentId: null,
          timestampSeconds: null,
          createdAt: null,
          replies: [],
        ),
      );
      when(() => remote.deleteComment('c9')).thenAnswer((_) async {});

      final created =
          await repository.createComment(trackId: 't1', content: 'new');
      await repository.deleteComment('c9');

      expect(created.id, 'c9');

      when(() => commentsRepository.getTrackComments('track'))
          .thenAnswer((_) async => [makeEntityComment('c1')]);
      when(
        () => commentsRepository.createComment(
          trackId: 'track',
          content: 'body',
          parentCommentId: null,
          timestampSeconds: null,
        ),
      ).thenAnswer((_) async => makeEntityComment('c2'));
      when(
        () => commentsRepository.createComment(
          trackId: 'track',
          content: 'reply',
          parentCommentId: 'p1',
          timestampSeconds: 12,
        ),
      ).thenAnswer((_) async => makeEntityComment('c2'));
      when(() => commentsRepository.deleteComment('c2'))
          .thenAnswer((_) async {});

      final getTrackComments = GetTrackCommentsUseCase(commentsRepository);
      final createComment = CreateCommentUseCase(commentsRepository);
      final replyToComment = ReplyToCommentUseCase(commentsRepository);
      final deleteComment = DeleteCommentUseCase(commentsRepository);

      final list = await getTrackComments('track');
      final createdRoot =
          await createComment(trackId: 'track', content: 'body');
      final createdReply = await replyToComment(
        trackId: 'track',
        parentCommentId: 'p1',
        content: 'reply',
        timestampSeconds: 12,
      );
      await deleteComment('c2');

      expect(list.length, 1);
      expect(createdRoot.id, 'c2');
      expect(createdReply.id, 'c2');
      verify(() => commentsRepository.deleteComment('c2')).called(1);
    });
  });
}
