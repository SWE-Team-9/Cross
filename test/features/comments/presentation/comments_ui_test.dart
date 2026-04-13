import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart'
    as auth_domain;
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/comments/domain/entities/comment_entity.dart';
import 'package:soundcloud_clone/features/comments/presentation/bloc/comments_cubit.dart';
import 'package:soundcloud_clone/features/comments/presentation/bloc/comments_state.dart';
import 'package:soundcloud_clone/features/comments/presentation/pages/track_comments_page.dart';
import 'package:soundcloud_clone/features/comments/presentation/widgets/comment_input_field.dart';
import 'package:soundcloud_clone/features/comments/presentation/widgets/comment_tile.dart';
import 'package:soundcloud_clone/features/comments/presentation/widgets/comments_list.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class MockCommentsCubit extends MockCubit<CommentsState>
    implements CommentsCubit {}

CommentEntity makeComment({
  required String id,
  required String content,
  String userId = 'user-1',
  String userDisplayName = 'Ali',
  int? timestampSeconds = 10,
  String? parentCommentId,
  List<CommentEntity> replies = const [],
}) {
  return CommentEntity(
    id: id,
    content: content,
    userId: userId,
    userDisplayName: userDisplayName,
    userAvatarUrl: null,
    parentCommentId: parentCommentId,
    timestampSeconds: timestampSeconds,
    createdAt: DateTime(2026, 1, 1),
    replies: replies,
  );
}

void main() {
  late MockAuthCubit authCubit;
  late MockCommentsCubit commentsCubit;

  const currentUser = auth_domain.User(
    id: 'user-1',
    email: 'ali@test.com',
    handle: 'ali',
  );

  setUp(() {
    authCubit = MockAuthCubit();
    commentsCubit = MockCommentsCubit();

    when(() => authCubit.state).thenReturn(AuthAuthenticated(currentUser));
    when(() => authCubit.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    when(() => commentsCubit.state).thenReturn(CommentsState.initial());
    when(() => commentsCubit.stream)
        .thenAnswer((_) => const Stream<CommentsState>.empty());
    when(() => commentsCubit.load(any())).thenAnswer((_) async {});
    when(
      () => commentsCubit.addComment(
        trackId: any(named: 'trackId'),
        content: any(named: 'content'),
        timestampSeconds: any(named: 'timestampSeconds'),
      ),
    ).thenAnswer((_) async {});
    when(() => commentsCubit.deleteComment(any())).thenAnswer((_) async {});
  });

  Widget wrapWithProviders(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<CommentsCubit>.value(value: commentsCubit),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('CommentInputField', () {
    testWidgets('shows timestamp label and submits trimmed text', (tester) async {
      String? submitted;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommentInputField(
              currentTimestampLabel: '1:35',
              onSubmit: (value) => submitted = value,
            ),
          ),
        ),
      );

      expect(find.text('Will post at 1:35'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '  great track  ');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      expect(submitted, 'great track');
      expect(find.text('great track'), findsNothing);
    });

    testWidgets('shows loading spinner and does not submit while submitting',
        (tester) async {
      var called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommentInputField(
              isSubmitting: true,
              onSubmit: (_) => called = true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.tap(find.byType(GestureDetector).last);
      await tester.pump();

      expect(called, isFalse);
    });
  });

  group('CommentTile', () {
    testWidgets('handles timestamp tap and delete action', (tester) async {
      var tappedTimestamp = false;
      var deleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommentTile(
              comment: makeComment(id: 'c1', content: 'Nice'),
              onDelete: () => deleted = true,
              onTapTimestamp: () => tappedTimestamp = true,
            ),
          ),
        ),
      );

      expect(find.text('Nice'), findsOneWidget);
      expect(find.text('0:10'), findsOneWidget);

      await tester.tap(find.text('0:10'));
      await tester.pump();
      expect(tappedTimestamp, isTrue);

      await tester.tap(find.text('Delete'));
      await tester.pump();
      expect(deleted, isTrue);
    });

    testWidgets('opens reply dialog and submits reply text', (tester) async {
      String? submittedReply;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommentTile(
              comment: makeComment(id: 'c1', content: 'Original'),
              onReplySubmitted: (value) => submittedReply = value,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Reply'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'reply body');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(submittedReply, 'reply body');
    });
  });

  group('CommentsList', () {
    testWidgets('renders replies, handles timestamp taps, and deletes own comments',
        (tester) async {
      int? tappedTimestamp;
      final parent = makeComment(
        id: 'parent',
        content: 'Parent comment',
        replies: [
          makeComment(
            id: 'reply',
            content: 'Reply comment',
            userId: 'user-2',
            userDisplayName: 'Salma',
            parentCommentId: 'parent',
            timestampSeconds: null,
          ),
        ],
      );

      await tester.pumpWidget(
        wrapWithProviders(
          CommentsList(
            comments: [parent],
            trackId: 'track-1',
            onSeekToTimestamp: (value) => tappedTimestamp = value,
          ),
        ),
      );

      expect(find.text('Parent comment'), findsOneWidget);
      expect(find.text('Reply comment'), findsOneWidget);

      await tester.tap(find.text('0:10'));
      await tester.pump();
      expect(tappedTimestamp, 10);

      await tester.tap(find.text('Delete').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      verify(() => commentsCubit.deleteComment('parent')).called(1);
    });
  });

  group('TrackCommentsPage', () {
    testWidgets('loads comments on init and shows loading state', (tester) async {
      when(() => commentsCubit.state)
          .thenReturn(CommentsState.initial().copyWith(isLoading: true));

      await tester.pumpWidget(
        wrapWithProviders(
          const TrackCommentsPage(trackId: 'track-1'),
        ),
      );

      verify(() => commentsCubit.load('track-1')).called(1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows retry UI for load errors', (tester) async {
      when(() => commentsCubit.state).thenReturn(
        CommentsState.initial().copyWith(errorMessage: 'boom'),
      );

      await tester.pumpWidget(
        wrapWithProviders(
          const TrackCommentsPage(trackId: 'track-1'),
        ),
      );

      expect(find.text('Failed to load comments'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      verify(() => commentsCubit.load('track-1')).called(greaterThan(1));
    });

    testWidgets('shows empty state and submits timestamped comments',
        (tester) async {
      when(() => commentsCubit.state).thenReturn(CommentsState.initial());

      await tester.pumpWidget(
        wrapWithProviders(
          TrackCommentsPage(
            trackId: 'track-1',
            getCurrentPositionSeconds: () => 95,
          ),
        ),
      );

      expect(find.text('No comments yet'), findsOneWidget);
      expect(find.text('Commenting at 1:35'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'First!');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      verify(
        () => commentsCubit.addComment(
          trackId: 'track-1',
          content: 'First!',
          timestampSeconds: 95,
        ),
      ).called(1);
    });
  });
}
