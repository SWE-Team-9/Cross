import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/recently_played/domain/usecases/get_recently_played.dart';
import 'package:soundcloud_clone/features/recently_played/presentation/bloc/recently_played_cubit.dart';

class MockGetRecentlyPlayed extends Mock implements GetRecentlyPlayed {}

class MockRecordRecentlyPlayed extends Mock implements RecordRecentlyPlayed {}

void main() {
  late RecentlyPlayedCubit cubit;

  Track createTrack(String id) {
    return Track(
      id: id,
      title: 'Track $id',
      artist: 'Artist $id',
      audioUrl: 'url_$id',
      artworkUrl: null,
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    cubit = RecentlyPlayedCubit();
  });

  tearDown(() {
    cubit.close();
  });

  test('initial state is empty', () {
    expect(cubit.state, <Track>[]);
  });

  test('adds a track to the top', () {
    final track = createTrack('1');

    cubit.addTrack(track);

    expect(cubit.state.length, 1);
    expect(cubit.state.first.id, '1');
  });

  test('adds multiple tracks in correct order (latest first)', () {
    final t1 = createTrack('1');
    final t2 = createTrack('2');

    cubit.addTrack(t1);
    cubit.addTrack(t2);

    expect(cubit.state.length, 2);
    expect(cubit.state[0].id, '2');
    expect(cubit.state[1].id, '1');
  });

  test('does not duplicate tracks, moves existing to top', () {
    final track = createTrack('1');

    cubit.addTrack(track);
    cubit.addTrack(track);

    expect(cubit.state.length, 1);
    expect(cubit.state.first.id, '1');
  });

  test('limits list to 20 items', () {
    for (int i = 0; i < 25; i++) {
      cubit.addTrack(createTrack(i.toString()));
    }

    expect(cubit.state.length, 20);
  });

  test('clear removes all tracks', () {
    cubit.addTrack(createTrack('1'));
    cubit.addTrack(createTrack('2'));

    cubit.clear();

    expect(cubit.state, <Track>[]);
  });

  test('loadListeningHistory restores local tracks without a remote loader',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'recent_tracks_local': jsonEncode([
        <String, dynamic>{
          'id': 'local_1',
          'title': 'Local Track',
          'artist': 'Local Artist',
          'audioUrl': 'local-url',
          'artworkUrl': 'local-art.jpg',
          'handle': 'local_artist',
          'artistId': 'artist_1',
          'likesCount': '8',
          'repostsCount': 2.6,
          'durationMs': '90000',
          'localPath': '/music/local_1.mp3',
        },
        <String, dynamic>{'title': 'Missing id'},
      ]),
    });
    await cubit.close();
    cubit = RecentlyPlayedCubit();

    await cubit.loadListeningHistory();

    expect(cubit.state, hasLength(1));
    expect(cubit.state.single.id, 'local_1');
    expect(cubit.state.single.title, 'Local Track');
    expect(cubit.state.single.artist, 'Local Artist');
    expect(cubit.state.single.artworkUrl, 'local-art.jpg');
    expect(cubit.state.single.handle, 'local_artist');
    expect(cubit.state.single.artistId, 'artist_1');
    expect(cubit.state.single.likesCount, 8);
    expect(cubit.state.single.repostsCount, 2);
    expect(cubit.state.single.durationMs, 90000);
    expect(cubit.state.single.localPath, '/music/local_1.mp3');
  });

  test('loadListeningHistory merges remote and local tracks', () async {
    final loader = MockGetRecentlyPlayed();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'recent_tracks_local': jsonEncode([
        <String, dynamic>{
          'id': 'shared',
          'title': 'Local Shared',
          'artist': 'Local',
          'audioUrl': '',
        },
        <String, dynamic>{
          'id': 'local_only',
          'title': 'Local Only',
          'artist': 'Local',
          'audioUrl': '',
        },
      ]),
    });
    when(() => loader()).thenAnswer(
      (_) async => [
        createTrack('remote'),
        createTrack('shared'),
        Track(id: '', title: 'No id', artist: 'Nobody', audioUrl: ''),
      ],
    );
    await cubit.close();
    cubit = RecentlyPlayedCubit(getRecentlyPlayed: loader);

    await cubit.loadListeningHistory();

    expect(cubit.state.map((track) => track.id), [
      'remote',
      'shared',
      'local_only',
    ]);
  });

  test('loadListeningHistory keeps local fallback when remote load fails',
      () async {
    final loader = MockGetRecentlyPlayed();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'recent_tracks_local': jsonEncode([
        <String, dynamic>{
          'id': 'local_1',
          'title': 'Local Track',
          'artist': 'Local',
          'audioUrl': '',
        },
      ]),
    });
    when(() => loader()).thenThrow(Exception('offline'));
    await cubit.close();
    cubit = RecentlyPlayedCubit(getRecentlyPlayed: loader);

    await cubit.loadListeningHistory();

    expect(cubit.state.map((track) => track.id), ['local_1']);
  });

  test('loadListeningHistory ignores malformed local history', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'recent_tracks_local': '{',
    });
    await cubit.close();
    cubit = RecentlyPlayedCubit();

    await cubit.loadListeningHistory();

    expect(cubit.state, isEmpty);
  });

  test('addTrack records remote play when recorder is configured', () async {
    final recorder = MockRecordRecentlyPlayed();
    when(() => recorder('1')).thenAnswer((_) async {});
    await cubit.close();
    cubit = RecentlyPlayedCubit(recordRecentlyPlayed: recorder);

    cubit.addTrack(createTrack('1'));
    await Future<void>.delayed(Duration.zero);

    verify(() => recorder('1')).called(1);
  });

  test('recordTrackPlay ignores recorder failures', () async {
    final recorder = MockRecordRecentlyPlayed();
    when(() => recorder('1')).thenThrow(Exception('offline'));
    await cubit.close();
    cubit = RecentlyPlayedCubit(recordRecentlyPlayed: recorder);

    await cubit.recordTrackPlay('1');

    verify(() => recorder('1')).called(1);
  });
}
