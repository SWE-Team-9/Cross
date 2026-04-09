import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';

import 'package:soundcloud_clone/core/models/player_state.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/home/presentation/pages/mock_home_page.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/recently_played/presentation/bloc/recently_played_cubit.dart';

class FakeAudioPlayerService implements AudioPlayerService {
  @override
  Stream<PlayerState> get playerStateStream =>
      const Stream<PlayerState>.empty();

  @override
  Future<void> play(track) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

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

    // 🔥 Register Audio Service
    GetIt.I.registerSingleton<AudioPlayerService>(
      FakeAudioPlayerService(),
    );

    // 🔥 Register Recently Played
    GetIt.I.registerSingleton<RecentlyPlayedCubit>(
      RecentlyPlayedCubit(),
    );

    mockAuthCubit = MockAuthCubit();

    when(() => mockAuthCubit.state).thenReturn(
      AuthAuthenticated(
        const User(
          id: '1',
          email: 'test@example.com',
          handle: 'test',
          displayName: 'Test User',
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
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(
            value: mockAuthCubit,
          ),

          // 🔥 CRITICAL FIX
          BlocProvider<PlayerCubit>(
            create: (_) => PlayerCubit(GetIt.I<AudioPlayerService>()),
          ),
        ],
        child: const MockHomePage(),
      ),
    );
  }

  testWidgets('Home page builds without crashing', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('Shows main sections', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.textContaining('Mixed'), findsOneWidget);
    expect(find.textContaining('Trending'), findsOneWidget);
  });
}
