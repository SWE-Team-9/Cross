import 'package:flutter_test/flutter_test.dart';
import 'package:audio_service/audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BaseAudioHandler handler;

  setUp(() {
    handler = BaseAudioHandler(); // ✅ no platform
  });

  test('mediaItem works', () {
    const item = MediaItem(
      id: '1',
      title: 'Test',
      artist: 'Artist',
    );

    handler.mediaItem.add(item);

    expect(handler.mediaItem.value, isNotNull);
    expect(handler.mediaItem.value!.title, 'Test');
  });

  test('playbackState updates', () {
    handler.playbackState.add(
      PlaybackState(
        controls: const [],
        systemActions: const {},
        androidCompactActionIndices: const [],
        processingState: AudioProcessingState.ready,
        playing: true,
        updatePosition: Duration.zero,
      ),
    );

    expect(handler.playbackState.value.playing, true);
  });

  test('playbackState emits values', () async {
    final emitted = <PlaybackState>[];

    final sub = handler.playbackState.listen(emitted.add);

    handler.playbackState.add(
      PlaybackState(
        controls: const [],
        systemActions: const {},
        androidCompactActionIndices: const [],
        processingState: AudioProcessingState.ready,
        playing: true,
        updatePosition: Duration.zero,
      ),
    );

    await Future.delayed(const Duration(milliseconds: 50));

    expect(emitted, isNotEmpty);

    await sub.cancel();
  });
}
