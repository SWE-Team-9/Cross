import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/recently_played/presentation/bloc/recently_played_cubit.dart';

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
}
