import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/picked_audio_file.dart';

void main() {
  group('PickedAudioFile', () {
    test('formattedSize returns bytes when size is less than 1 KB', () {
      const file = PickedAudioFile(
        name: 'a.mp3',
        extension: 'mp3',
        sizeInBytes: 512,
        path: '/tmp/a.mp3',
      );

      expect(file.formattedSize, '512 B');
    });

    test('formattedSize returns KB when size is less than 1 MB', () {
      const file = PickedAudioFile(
        name: 'a.mp3',
        extension: 'mp3',
        sizeInBytes: 1536,
        path: '/tmp/a.mp3',
      );

      expect(file.formattedSize, '1.5 KB');
    });

    test('formattedSize returns MB when size is 1 MB or more', () {
      const file = PickedAudioFile(
        name: 'a.mp3',
        extension: 'mp3',
        sizeInBytes: 2 * 1024 * 1024,
        path: '/tmp/a.mp3',
      );

      expect(file.formattedSize, '2.0 MB');
    });

    test('supports value equality through Equatable', () {
      const first = PickedAudioFile(
        name: 'a.mp3',
        extension: 'mp3',
        sizeInBytes: 1000,
        path: '/tmp/a.mp3',
      );

      const second = PickedAudioFile(
        name: 'a.mp3',
        extension: 'mp3',
        sizeInBytes: 1000,
        path: '/tmp/a.mp3',
      );

      expect(first, second);
    });
  });
}
