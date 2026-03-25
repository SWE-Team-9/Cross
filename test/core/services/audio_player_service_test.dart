import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:soundcloud_clone/core/models/player_state.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/services/implementations/just_audio_player_service.dart';
import 'package:soundcloud_clone/features/recently_played/presentation/bloc/recently_played_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late JustAudioPlayerService service;
  late RecentlyPlayedCubit recentlyPlayedCubit;

  const invalidTrack = Track(
    id: 't1',
    title: 'Broken Track',
    artist: 'Ali',
    audioUrl: 'not-a-valid-url',
  );

  setUp(() {
    GetIt.I.reset();

    recentlyPlayedCubit = RecentlyPlayedCubit();
    GetIt.I.registerSingleton<RecentlyPlayedCubit>(recentlyPlayedCubit);

    service = JustAudioPlayerService();
  });

  tearDown(() async {
    await service.dispose();
    await recentlyPlayedCubit.close();
    await GetIt.I.reset();
  });

  test('service can be created', () {
    expect(service, isNotNull);
  });

  test('playerStateStream emits paused after pause()', () async {
    final emitted = <PlayerState>[];
    final sub = service.playerStateStream.listen(emitted.add);

    await service.pause();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(emitted, isNotEmpty);
    expect(emitted.last.status, PlayerStatus.paused);

    await sub.cancel();
  });

  test('playerStateStream emits idle with zero position after stop()', () async {
    final emitted = <PlayerState>[];
    final sub = service.playerStateStream.listen(emitted.add);

    await service.stop();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(emitted, isNotEmpty);
    expect(emitted.last.status, PlayerStatus.idle);
    expect(emitted.last.position, Duration.zero);

    await sub.cancel();
  });

  test('seek works', () async {
    await service.seek(const Duration(seconds: 10));
  });


  test('playerStateStream is broadcast', () async {
    final emitted1 = <PlayerState>[];
    final emitted2 = <PlayerState>[];

    final sub1 = service.playerStateStream.listen(emitted1.add);
    final sub2 = service.playerStateStream.listen(emitted2.add);

    await service.pause();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(emitted1, isNotEmpty);
    expect(emitted2, isNotEmpty);
    expect(emitted1.last.status, PlayerStatus.paused);
    expect(emitted2.last.status, PlayerStatus.paused);

    await sub1.cancel();
    await sub2.cancel();
  });

  test('dispose does not crash', () async {
    final localService = JustAudioPlayerService();
    await localService.dispose();
  });
}