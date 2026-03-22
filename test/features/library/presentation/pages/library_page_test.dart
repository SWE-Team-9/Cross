import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:soundcloud_clone/features/library/presentation/pages/library_page.dart';
import 'package:soundcloud_clone/features/recently_played/presentation/bloc/recently_played_cubit.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';
import 'package:soundcloud_clone/core/models/player_state.dart';

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
  setUp(() async {
    await GetIt.I.reset();

    GetIt.I.registerSingleton<AudioPlayerService>(
      FakeAudioPlayerService(),
    );
  });

  Widget buildTestWidget() {
    return const MaterialApp(
      home: LibraryPage(),
    );
  }

  testWidgets('LibraryPage builds without crashing', (tester) async {
    GetIt.I.registerSingleton<RecentlyPlayedCubit>(
      RecentlyPlayedCubit(),
    );

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.byType(Scaffold), findsOneWidget);
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

    // ✅ Check that empty message is gone
    expect(find.textContaining('No recently'), findsNothing);
  });
}
