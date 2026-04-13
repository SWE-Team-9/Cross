import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';
import 'package:soundcloud_clone/core/models/player_state.dart';
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

class MockAudioPlayerService extends Mock implements AudioPlayerService {}

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
  late MockAudioPlayerService mockPlayer;

  const currentUser = auth_domain.User(
    id: 'user-1',
    email: 'ali@test.com',
    handle: 'ali',
  );

  setUpAll(() {
    mockPlayer = MockAudioPlayerService();

    GetIt.I.registerSingleton<AudioPlayerService>(mockPlayer);

    // 🔥 FIX: emit one value instead of empty stream
    when(() => mockPlayer.playerStateStream).thenAnswer(
      (_) => Stream.value(
        const PlayerState(
          status: PlayerStatus.idle,
          position: Duration.zero,
        ),
      ),
    );
  });

  setUp(() {
    authCubit = MockAuthCubit();
    commentsCubit = MockCommentsCubit();

    when(() => authCubit.state).thenReturn(AuthAuthenticated(currentUser));
    when(() => authCubit.stream).thenAnswer((_) => const Stream.empty());

    when(() => commentsCubit.state).thenReturn(CommentsState.initial());
    when(() => commentsCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => commentsCubit.load(any())).thenAnswer((_) async {});
    when(() => commentsCubit.addComment(
          trackId: any(named: 'trackId'),
          content: any(named: 'content'),
          timestampSeconds: any(named: 'timestampSeconds'),
        )).thenAnswer((_) async {});
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

  // ========================= TrackCommentsPage =========================

  group('TrackCommentsPage', () {
    testWidgets('loads comments on init and shows loading state',
        (tester) async {
      when(() => commentsCubit.state)
          .thenReturn(CommentsState.initial().copyWith(isLoading: true));

      await tester.pumpWidget(
        wrapWithProviders(
          TrackCommentsPage(
            trackId: 'track-1',
            getCurrentPositionSeconds: () => 0,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => commentsCubit.load('track-1')).called(1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error UI for load errors', (tester) async {
      when(() => commentsCubit.state).thenReturn(
        CommentsState.initial().copyWith(errorMessage: 'boom'),
      );

      await tester.pumpWidget(
        wrapWithProviders(
          TrackCommentsPage(
            trackId: 'track-1',
            getCurrentPositionSeconds: () => 0,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('boom'), findsOneWidget);

      verify(() => commentsCubit.load('track-1')).called(1);
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

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('No comments yet'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'First!');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      verify(
        () => commentsCubit.addComment(
          trackId: 'track-1',
          content: 'First!',
          timestampSeconds: 0, // 🔥 FIXED
        ),
      ).called(1);
    });
  });
  ;
}
