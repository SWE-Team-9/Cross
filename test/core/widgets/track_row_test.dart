import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:soundcloud_clone/core/widgets/track_row.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';
import 'package:soundcloud_clone/core/models/player_state.dart';

/// Fake player
class FakeAudioPlayerService implements AudioPlayerService {
  bool playCalled = false;
  String? lastTrackId;

  @override
  Stream<PlayerState> get playerStateStream => Stream.value(
        const PlayerState(
          status: PlayerStatus.idle,
          position: Duration.zero,
        ),
      );

  @override
  Future<void> play(String url, String trackId) async {
    playCalled = true;
    lastTrackId = trackId;
  }

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
  late FakeAudioPlayerService fakePlayer;

  setUp(() async {
    await GetIt.I.reset(); // VERY IMPORTANT

    fakePlayer = FakeAudioPlayerService();

    GetIt.I.registerSingleton<AudioPlayerService>(fakePlayer);
  });

  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  testWidgets('TrackRow renders title and artist', (tester) async {
    final track = Track(
      id: '1',
      title: 'Test Song',
      artist: 'Test Artist',
      audioUrl: 'url',
    );

    await tester.pumpWidget(buildTestWidget(TrackRow(track: track)));

    await tester.pump(); // ensure build completes

    expect(find.text('Test Song'), findsOneWidget);
    expect(find.text('Test Artist'), findsOneWidget);
  });

  testWidgets('TrackRow calls play on tap', (tester) async {
    final track = Track(
      id: '1',
      title: 'Test Song',
      artist: 'Test Artist',
      audioUrl: 'url',
    );

    await tester.pumpWidget(buildTestWidget(TrackRow(track: track)));

    await tester.pump();

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(TrackRow)),
    );
    await gesture.up();

    await tester.pumpAndSettle();

    expect(fakePlayer.playCalled, true);
    expect(fakePlayer.lastTrackId, '1');
  });
}
