import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/models/player_state.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/home/presentation/pages/mock_home_page.dart';
import 'package:soundcloud_clone/features/recently_played/presentation/bloc/recently_played_cubit.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class FakeAudioPlayerService implements AudioPlayerService {
  @override
  Stream<PlayerState> get playerStateStream => const Stream.empty();

  @override
  Future<void> play(track) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> dispose() async {}
}

void main() {
  late MockAuthCubit mockAuthCubit;

  setUp(() async {
    await GetIt.I.reset();

    GetIt.I.registerSingleton<AudioPlayerService>(
      FakeAudioPlayerService(),
    );
    GetIt.I.registerSingleton<RecentlyPlayedCubit>(
      RecentlyPlayedCubit(),
    );

    mockAuthCubit = MockAuthCubit();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: BlocProvider<AuthCubit>.value(
        value: mockAuthCubit,
        child: const MockHomePage(),
      ),
    );
  }

  group('MockHomePage', () {
    testWidgets('calls logout after confirming from logout sheet',
        (tester) async {
      when(() => mockAuthCubit.state).thenReturn(
        AuthAuthenticated(
          const User(
            id: '1',
            email: 'ali@example.com',
            handle: 'ali',
            displayName: 'Ali',
            avatarUrl: null,
          ),
        ),
      );
      when(() => mockAuthCubit.logout()).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.logout_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Log out of Iqa3?'), findsOneWidget); // التعديل هنا
      expect(find.text('Log out'), findsOneWidget);

      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();

      verify(() => mockAuthCubit.logout()).called(1);
    });

    testWidgets('calls logout after confirming from logout sheet',
        (tester) async {
      when(() => mockAuthCubit.state).thenReturn(
        AuthAuthenticated(
          const User(
            id: '1',
            email: 'ali@example.com',
            handle: 'ali',
            displayName: 'Ali',
            avatarUrl: null,
          ),
        ),
      );
      when(() => mockAuthCubit.logout()).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.logout_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Log out of Iqa3?'), findsOneWidget); // التعديل هنا
      expect(find.text('Log out'), findsOneWidget);

      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();

      verify(() => mockAuthCubit.logout()).called(1);
    });
    testWidgets('renders bottom navigation labels', (tester) async {
      when(() => mockAuthCubit.state).thenReturn(
        AuthAuthenticated(
          const User(
            id: '1',
            email: 'ali@example.com',
            handle: 'ali',
            displayName: 'Ali',
            avatarUrl: null,
          ),
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Home'), findsWidgets);
      expect(find.text('Feed'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
    });

    testWidgets('shows top content sections that exist on current home page',
        (tester) async {
      when(() => mockAuthCubit.state).thenReturn(
        AuthAuthenticated(
          const User(
            id: '1',
            email: 'ali@example.com',
            handle: 'ali',
            displayName: 'Ali',
            avatarUrl: null,
          ),
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('More of what you like'), findsOneWidget);
      expect(find.text('Mixed for you'), findsOneWidget);
      expect(find.text('Your Tracks (Sprint 2 Test)'), findsOneWidget);
      expect(find.text('Trending by genre'), findsOneWidget);
    });

    testWidgets('shows logout confirmation sheet when logout icon is tapped',
        (tester) async {
      when(() => mockAuthCubit.state).thenReturn(
        AuthAuthenticated(
          const User(
            id: '1',
            email: 'ali@example.com',
            handle: 'ali',
            displayName: 'Ali',
            avatarUrl: null,
          ),
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.logout_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Log out of Iqa3?'), findsOneWidget); // التعديل هنا
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Log out'), findsOneWidget);
    });

    testWidgets('shows owner track management buttons', (tester) async {
      when(() => mockAuthCubit.state).thenReturn(
        AuthAuthenticated(
          const User(
            id: '1',
            email: 'ali@example.com',
            handle: 'ali',
            displayName: 'Ali',
            avatarUrl: null,
          ),
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Manage'), findsNWidgets(2));
      expect(find.text('Midnight Echoes'), findsOneWidget);
      expect(find.text('City Lights'), findsOneWidget);
    });
    testWidgets('renders core home sections for authenticated user',
        (tester) async {
      when(() => mockAuthCubit.state).thenReturn(
        AuthAuthenticated(
          const User(
            id: '1',
            email: 'ali@example.com',
            handle: 'ali',
            displayName: 'Ali',
            avatarUrl: null,
          ),
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Home'), findsNWidgets(2));
      expect(find.text('GET PRO'), findsOneWidget);
      expect(find.text('More of what you like'), findsOneWidget);
      expect(find.text('Mixed for you'), findsOneWidget);
      expect(find.text('Your Tracks (Sprint 2 Test)'), findsOneWidget);
      expect(find.text('Trending by genre'), findsOneWidget);
    });

    testWidgets('shows authenticated user fallback avatar initial',
        (tester) async {
      when(() => mockAuthCubit.state).thenReturn(
        AuthAuthenticated(
          const User(
            id: '1',
            email: 'ali@example.com',
            handle: 'ali',
            displayName: 'Ali',
            avatarUrl: null,
          ),
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('A'), findsOneWidget);
      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    });

    testWidgets('does not show logout icon for unauthenticated state',
        (tester) async {
      when(() => mockAuthCubit.state).thenReturn(AuthUnauthenticated());

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.logout_rounded), findsNothing);
      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('displays managed tracks section content', (tester) async {
      when(() => mockAuthCubit.state).thenReturn(
        AuthAuthenticated(
          const User(
            id: '1',
            email: 'ali@example.com',
            handle: 'ali',
            displayName: 'Ali',
            avatarUrl: null,
          ),
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Midnight Echoes'), findsOneWidget);
      expect(find.text('City Lights'), findsOneWidget);
      expect(find.text('Manage'), findsNWidgets(2));
    });

    testWidgets('changes selected genre chip on tap', (tester) async {
      when(() => mockAuthCubit.state).thenReturn(
        AuthAuthenticated(
          const User(
            id: '1',
            email: 'ali@example.com',
            handle: 'ali',
            displayName: 'Ali',
            avatarUrl: null,
          ),
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      await tester.ensureVisible(find.text('POP'));
      await tester.tap(find.text('POP'));
      await tester.pump();

      expect(find.text('POP'), findsOneWidget);
      expect(find.text('ELECTRONIC'), findsOneWidget);
    });

    testWidgets('shows snackbar when auth error state is emitted',
        (tester) async {
      when(() => mockAuthCubit.state).thenReturn(AuthInitial());
      whenListen(
        mockAuthCubit,
        Stream<AuthState>.fromIterable([
          AuthError('Something went wrong'),
        ]),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Something went wrong'), findsOneWidget);
    });
  });
}
