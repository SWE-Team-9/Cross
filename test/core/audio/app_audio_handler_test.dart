import 'package:flutter_test/flutter_test.dart';
import 'package:audio_service/audio_service.dart';

// نتيست BaseAudioHandler لأن AppAudioHandler يحتاج platform channels
// اللي مش متاحة في بيئة التيست بدون تعديل الكود الأصلي
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BaseAudioHandler handler;

  setUp(() {
    handler = BaseAudioHandler();
  });

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
  });

  group('playbackState', () {
    PlaybackState makeState(
        {bool playing = false,
        AudioProcessingState processingState = AudioProcessingState.idle}) {
      return PlaybackState(
        controls: const [],
        systemActions: const {},
        androidCompactActionIndices: const [],
        processingState: processingState,
        playing: playing,
        updatePosition: Duration.zero,
      );
    }

    test('initial playing is false', () {
      expect(handler.playbackState.value.playing, false);
    });

    test('updates playing to true', () {
      handler.playbackState.add(makeState(playing: true));
      expect(handler.playbackState.value.playing, true);
    });

    test('updates processingState to ready', () {
      handler.playbackState
          .add(makeState(processingState: AudioProcessingState.ready));
      expect(handler.playbackState.value.processingState,
          AudioProcessingState.ready);
    });

    test('updates processingState to buffering', () {
      handler.playbackState
          .add(makeState(processingState: AudioProcessingState.buffering));
      expect(handler.playbackState.value.processingState,
          AudioProcessingState.buffering);
    });

    test('updates processingState to completed', () {
      handler.playbackState
          .add(makeState(processingState: AudioProcessingState.completed));
      expect(handler.playbackState.value.processingState,
          AudioProcessingState.completed);
    });

    test('emits values to listeners', () async {
      final emitted = <PlaybackState>[];
      final sub = handler.playbackState.listen(emitted.add);
      handler.playbackState.add(makeState(playing: true));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(emitted, isNotEmpty);
      expect(emitted.last.playing, true);
      await sub.cancel();
    });

    test('emits multiple values in order', () async {
      final emitted = <PlaybackState>[];
      final sub = handler.playbackState.listen(emitted.add);
      handler.playbackState.add(makeState(playing: false));
      handler.playbackState.add(makeState(playing: true));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(emitted.length, greaterThanOrEqualTo(2));
      expect(emitted.last.playing, true);
      await sub.cancel();
    });

    test('updatePosition is set correctly', () {
      final pos = const Duration(seconds: 42);
      handler.playbackState.add(PlaybackState(
        controls: const [],
        systemActions: const {},
        androidCompactActionIndices: const [],
        processingState: AudioProcessingState.ready,
        playing: true,
        updatePosition: pos,
      ));
      expect(handler.playbackState.value.updatePosition, pos);
    });
  });

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
  });
}
