import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/playback_state.dart';
import 'package:soundcloud_clone/core/models/track.dart';

void main() {
  group('PlaybackState', () {
    test('initial state has default values', () {
      const state = PlaybackState(isAvailable: true);
      expect(state.isAvailable, isTrue);
      expect(state.isPlaying, isFalse);
      expect(state.currentTrack, isNull);
      expect(state.queue, isEmpty);
    });

    test('copyWith creates correct new state', () {
      const track1 = Track(
        id: '1',
        title: 'Track 1',
        artist: 'Artist 1',
        audioUrl: 'https://example.com/1.mp3',
      );
      const track2 = Track(
        id: '2',
        title: 'Track 2',
        artist: 'Artist 2',
        audioUrl: 'https://example.com/2.mp3',
      );

      const state = PlaybackState(
        isAvailable: true,
        isPlaying: false,
        currentTrack: track1,
        queue: [track1],
      );

      final newState = state.copyWith(
        isPlaying: true,
        currentTrack: track2,
        queue: [track1, track2],
      );

      expect(newState.isPlaying, isTrue);
      expect(newState.currentTrack, track2);
      expect(newState.queue.length, 2);
    });

    test('copyWith preserves unchanged fields', () {
      const state = PlaybackState(
        isAvailable: false,
        isPlaying: true,
      );

      final newState = state.copyWith(isPlaying: false);

      expect(newState.isAvailable, isFalse);
      expect(newState.isPlaying, isFalse);
    });

    test('equality works correctly', () {
      const track1 = Track(
        id: '1',
        title: 'Track 1',
        artist: 'Artist 1',
        audioUrl: 'https://example.com/1.mp3',
      );

      const state1 = PlaybackState(
        isAvailable: true,
        isPlaying: true,
        currentTrack: track1,
        queue: [track1],
      );

      const state2 = PlaybackState(
        isAvailable: true,
        isPlaying: true,
        currentTrack: track1,
        queue: [track1],
      );

      expect(state1, state2);
    });

    test('inequality works correctly', () {
      const track1 = Track(
        id: '1',
        title: 'Track 1',
        artist: 'Artist 1',
        audioUrl: 'https://example.com/1.mp3',
      );
      const track2 = Track(
        id: '2',
        title: 'Track 2',
        artist: 'Artist 2',
        audioUrl: 'https://example.com/2.mp3',
      );

      const state1 = PlaybackState(
        isAvailable: true,
        isPlaying: true,
        currentTrack: track1,
      );

      const state2 = PlaybackState(
        isAvailable: true,
        isPlaying: true,
        currentTrack: track2,
      );

      expect(state1 != state2, isTrue);
    });
  });
}
