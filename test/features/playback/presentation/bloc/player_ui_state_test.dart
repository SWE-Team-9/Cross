import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/models/player_state.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_ui_state.dart';

void main() {
  group('PlayerUIState', () {
    const track = Track(
      id: 't1',
      title: 'Song',
      artist: 'Artist',
      audioUrl: 'https://example.com/song.mp3',
    );

    const state = PlayerUIState(
      playerState: PlayerState(
        status: PlayerStatus.playing,
        position: Duration(seconds: 3),
        duration: Duration(seconds: 10),
      ),
      currentTrack: track,
    );

    test('copyWith updates selected fields', () {
      final updated = state.copyWith(
        playerState: const PlayerState(
          status: PlayerStatus.paused,
          position: Duration(seconds: 5),
          duration: Duration(seconds: 10),
        ),
      );

      expect(updated.playerState.status, PlayerStatus.paused);
      expect(updated.currentTrack, track);
    });

    test('status helpers map from player state', () {
      expect(state.isPlaying, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.isBuffering, isFalse);
    });

    test('position and duration proxy values', () {
      expect(state.position, const Duration(seconds: 3));
      expect(state.duration, const Duration(seconds: 10));
    });

    test('loading state reports loading helper true', () {
      const loading = PlayerUIState(
        playerState: PlayerState(
          status: PlayerStatus.loading,
          position: Duration.zero,
        ),
      );

      expect(loading.isLoading, isTrue);
      expect(loading.isPlaying, isFalse);
    });
  });
}
