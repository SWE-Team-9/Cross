import 'package:flutter_test/flutter_test.dart';
import 'package:audio_service/audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BaseAudioHandler handler;

  setUp(() {
    handler = BaseAudioHandler(); // ✅ PURE, NO PLATFORM
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
        playing: true,
        processingState: AudioProcessingState.ready,
      ),
    );

    expect(handler.playbackState.value.playing, true);
  });
}
