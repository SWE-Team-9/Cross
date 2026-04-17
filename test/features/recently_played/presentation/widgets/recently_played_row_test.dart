import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:soundcloud_clone/core/models/player_state.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/recently_played/presentation/widgets/recently_played_card.dart';
import 'package:soundcloud_clone/features/recently_played/presentation/widgets/recently_played_row.dart';

class FakeAudioPlayerService implements AudioPlayerService {
  @override
  Stream<PlayerState> get playerStateStream =>
      const Stream<PlayerState>.empty();

  @override
  Future<void> play(Track track) async {}

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
  @override
  Future<void> playFromContext({
    required List<Track> tracks,
    required int startIndex,
    required String source,
  }) async {}
}

void main() {
  const tracks = <Track>[
    Track(
      id: '1',
      title: 'Track One',
      artist: 'Artist One',
      audioUrl: 'https://example.com/1.mp3',
      artworkUrl: null,
      handle: 'artist-one',
    ),
    Track(
      id: '2',
      title: 'Track Two',
      artist: 'Artist Two',
      audioUrl: 'https://example.com/2.mp3',
      artworkUrl: null,
      handle: 'artist-two',
    ),
  ];

  Widget wrap(Widget child) {
    return MaterialApp(
      home: BlocProvider(
        create: (_) => PlayerCubit(GetIt.I<AudioPlayerService>()),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: child,
        ),
      ),
    );
  }

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<AudioPlayerService>(
      FakeAudioPlayerService(),
    );
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  group('RecentlyPlayedRow', () {
    testWidgets('returns empty SizedBox when tracks is empty', (tester) async {
      await tester.pumpWidget(
        wrap(const RecentlyPlayedRow(tracks: <Track>[])),
      );
      await tester.pump();

      expect(find.text('Recently played'), findsNothing);
      expect(find.byType(RecentlyPlayedCard), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('renders header and visible cards when tracks exist',
        (tester) async {
      await tester.pumpWidget(
        wrap(const RecentlyPlayedRow(tracks: tracks)),
      );
      await tester.pump();

      expect(find.text('Recently played'), findsOneWidget);
      expect(find.text('Track One'), findsOneWidget);
      expect(find.byType(RecentlyPlayedCard), findsAtLeastNWidgets(1));
    });

    testWidgets('shows See all button and triggers callback when provided',
        (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        wrap(
          RecentlyPlayedRow(
            tracks: tracks,
            onSeeAll: () => tapped = true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('See all'), findsOneWidget);

      await tester.tap(find.text('See all'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('does not show See all button when callback is null',
        (tester) async {
      await tester.pumpWidget(
        wrap(const RecentlyPlayedRow(tracks: tracks)),
      );
      await tester.pump();

      expect(find.text('See all'), findsNothing);
      expect(find.text('Track One'), findsOneWidget);
    });
  });
}
