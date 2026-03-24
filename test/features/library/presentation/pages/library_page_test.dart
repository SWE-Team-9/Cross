import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:soundcloud_clone/core/models/player_state.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/library/presentation/pages/library_page.dart';
import 'package:soundcloud_clone/features/recently_played/presentation/bloc/recently_played_cubit.dart';

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

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  late MockAuthCubit mockAuthCubit;

  setUp(() async {
    await GetIt.I.reset();

    GetIt.I.registerSingleton<AudioPlayerService>(
      FakeAudioPlayerService(),
    );

    mockAuthCubit = MockAuthCubit();

    when(() => mockAuthCubit.state).thenReturn(
      AuthAuthenticated(
        const User(
          id: '1',
          email: 'eyad@example.com',
          handle: 'eyad',
          displayName: 'Eyad',
          avatarUrl: null,
        ),
      ),
    );
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: BlocProvider<AuthCubit>.value(
        value: mockAuthCubit,
        child: const LibraryPage(),
      ),
    );
  }

  testWidgets('LibraryPage builds without crashing', (tester) async {
    GetIt.I.registerSingleton<RecentlyPlayedCubit>(
      RecentlyPlayedCubit(),
    );

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('Library'), findsNWidgets(2));
  });

  testWidgets('shows empty state when no tracks', (tester) async {
    GetIt.I.registerSingleton<RecentlyPlayedCubit>(
      RecentlyPlayedCubit(),
    );

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.textContaining('No recently'), findsOneWidget);
  });

  testWidgets('shows recently played content when tracks exist',
      (tester) async {
    final cubit = RecentlyPlayedCubit();

    cubit.addTrack(
      Track(
        id: '1',
        title: 'Test Song',
        artist: 'Test Artist',
        audioUrl: 'url',
      ),
    );

    GetIt.I.registerSingleton<RecentlyPlayedCubit>(cubit);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.textContaining('No recently'), findsNothing);
  });
}
