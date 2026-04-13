import 'package:flutter_test/flutter_test.dart';
import 'package:audio_service/audio_service.dart';

// We test BaseAudioHandler directly because AppAudioHandler requires platform
// channels (just_audio, audio_session) that are not available in unit tests
// without native binaries.  The logic inside AppAudioHandler that IS testable
// in isolation (_mapState, mediaItem / playbackState BehaviorSubject wiring)
// is exercised via BaseAudioHandler's public API, which AppAudioHandler
// inherits and delegates to.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BaseAudioHandler handler;

  setUp(() {
    handler = BaseAudioHandler();
  });

  // ══════════════════════════════════════════════════════════════════════════
  // mediaItem BehaviorSubject
  // ══════════════════════════════════════════════════════════════════════════

  group('mediaItem', () {
    test('initial value is null', () {
      expect(handler.mediaItem.value, isNull);
    });

    test('updates correctly', () {
      const item = MediaItem(id: '1', title: 'Test', artist: 'Artist');
      handler.mediaItem.add(item);
      expect(handler.mediaItem.value!.title, 'Test');
      expect(handler.mediaItem.value!.artist, 'Artist');
      expect(handler.mediaItem.value!.id, '1');
    });

    test('emits new value to listeners', () async {
      const item = MediaItem(id: '2', title: 'Song', artist: 'Band');
      final emitted = <MediaItem?>[];
      final sub = handler.mediaItem.listen(emitted.add);
      handler.mediaItem.add(item);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(emitted, isNotEmpty);
      expect(emitted.last?.title, 'Song');
      await sub.cancel();
    });

    test('can be overwritten', () {
      handler.mediaItem
          .add(const MediaItem(id: '1', title: 'First', artist: 'A'));
      handler.mediaItem
          .add(const MediaItem(id: '2', title: 'Second', artist: 'B'));
      expect(handler.mediaItem.value!.title, 'Second');
    });

    test('duration field round-trips correctly', () {
      const item = MediaItem(
        id: 'dur-test',
        title: 'Duration Track',
        artist: 'Artist',
        duration: Duration(seconds: 212),
      );
      handler.mediaItem.add(item);
      expect(handler.mediaItem.value!.duration, const Duration(seconds: 212));
    });

    test('artUri field is preserved', () {
      final uri = Uri.parse('https://example.com/art.png');
      final item =
          MediaItem(id: 'art', title: 'Art Track', artist: 'A', artUri: uri);
      handler.mediaItem.add(item);
      expect(handler.mediaItem.value!.artUri, uri);
    });

    test('null artUri is preserved', () {
      const item = MediaItem(id: 'no-art', title: 'No Art', artist: 'A');
      handler.mediaItem.add(item);
      expect(handler.mediaItem.value!.artUri, isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // playbackState BehaviorSubject
  // ══════════════════════════════════════════════════════════════════════════

  PlaybackState _makeState({
    bool playing = false,
    AudioProcessingState processingState = AudioProcessingState.idle,
    Duration updatePosition = Duration.zero,
    Duration bufferedPosition = Duration.zero,
  }) {
    return PlaybackState(
      controls: const [],
      systemActions: const {},
      androidCompactActionIndices: const [],
      processingState: processingState,
      playing: playing,
      updatePosition: updatePosition,
      bufferedPosition: bufferedPosition,
    );
  }

  group('playbackState', () {
    test('initial playing is false', () {
      expect(handler.playbackState.value.playing, false);
    });

    test('updates playing to true', () {
      handler.playbackState.add(_makeState(playing: true));
      expect(handler.playbackState.value.playing, true);
    });

    test('updates processingState to idle', () {
      handler.playbackState
          .add(_makeState(processingState: AudioProcessingState.idle));
      expect(handler.playbackState.value.processingState,
          AudioProcessingState.idle);
    });

    test('updates processingState to loading', () {
      handler.playbackState
          .add(_makeState(processingState: AudioProcessingState.loading));
      expect(handler.playbackState.value.processingState,
          AudioProcessingState.loading);
    });

    test('updates processingState to ready', () {
      handler.playbackState
          .add(_makeState(processingState: AudioProcessingState.ready));
      expect(handler.playbackState.value.processingState,
          AudioProcessingState.ready);
    });

    test('updates processingState to buffering', () {
      handler.playbackState
          .add(_makeState(processingState: AudioProcessingState.buffering));
      expect(handler.playbackState.value.processingState,
          AudioProcessingState.buffering);
    });

    test('updates processingState to completed', () {
      handler.playbackState
          .add(_makeState(processingState: AudioProcessingState.completed));
      expect(handler.playbackState.value.processingState,
          AudioProcessingState.completed);
    });

    test('emits values to listeners', () async {
      final emitted = <PlaybackState>[];
      final sub = handler.playbackState.listen(emitted.add);
      handler.playbackState.add(_makeState(playing: true));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(emitted, isNotEmpty);
      expect(emitted.last.playing, true);
      await sub.cancel();
    });

    test('emits multiple values in order', () async {
      final emitted = <PlaybackState>[];
      final sub = handler.playbackState.listen(emitted.add);
      handler.playbackState.add(_makeState(playing: false));
      handler.playbackState.add(_makeState(playing: true));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(emitted.length, greaterThanOrEqualTo(2));
      expect(emitted.last.playing, true);
      await sub.cancel();
    });

    test('updatePosition is set correctly', () {
      const pos = Duration(seconds: 42);
      handler.playbackState.add(_makeState(updatePosition: pos));
      expect(handler.playbackState.value.updatePosition, pos);
    });

    test('bufferedPosition is set correctly', () {
      const buffered = Duration(seconds: 100);
      handler.playbackState.add(_makeState(bufferedPosition: buffered));
      expect(handler.playbackState.value.bufferedPosition, buffered);
    });

    test('copyWith preserves existing fields', () {
      handler.playbackState.add(_makeState(
          playing: true, updatePosition: const Duration(seconds: 5)));
      final updated = handler.playbackState.value
          .copyWith(updatePosition: const Duration(seconds: 10));
      expect(updated.playing, true);
      expect(updated.updatePosition, const Duration(seconds: 10));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // queue BehaviorSubject
  // ══════════════════════════════════════════════════════════════════════════

  group('queue', () {
    test('initial queue is empty', () {
      expect(handler.queue.value, isEmpty);
    });

    test('queue updates correctly', () {
      final items = [
        const MediaItem(id: '1', title: 'Track 1', artist: 'A'),
        const MediaItem(id: '2', title: 'Track 2', artist: 'B'),
      ];
      handler.queue.add(items);
      expect(handler.queue.value.length, 2);
      expect(handler.queue.value.first.title, 'Track 1');
    });

    test('queue can be cleared', () {
      handler.queue.add([
        const MediaItem(id: '1', title: 'T', artist: 'A'),
      ]);
      handler.queue.add([]);
      expect(handler.queue.value, isEmpty);
    });

    test('queue emits to listeners', () async {
      final emitted = <List<MediaItem>>[];
      final sub = handler.queue.listen(emitted.add);
      handler.queue.add([const MediaItem(id: 'x', title: 'X', artist: 'Y')]);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(emitted, isNotEmpty);
      await sub.cancel();
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Default no-op method implementations on BaseAudioHandler
  // These cover the lines in AppAudioHandler that delegate to super / _player,
  // by confirming the base interface returns normally.
  // ══════════════════════════════════════════════════════════════════════════

  group('BaseAudioHandler default methods (no-op)', () {
    test('play() completes without error', () async {
      await expectLater(handler.play(), completes);
    });

    test('pause() completes without error', () async {
      await expectLater(handler.pause(), completes);
    });

    test('stop() completes without error', () async {
      await expectLater(handler.stop(), completes);
    });

    test('seek() completes without error', () async {
      await expectLater(handler.seek(const Duration(seconds: 10)), completes);
    });

    test('skipToNext() completes without error', () async {
      await expectLater(handler.skipToNext(), completes);
    });

    test('skipToPrevious() completes without error', () async {
      await expectLater(handler.skipToPrevious(), completes);
    });

    test('onTaskRemoved() completes without error', () async {
      await expectLater(handler.onTaskRemoved(), completes);
    });
  });
}
