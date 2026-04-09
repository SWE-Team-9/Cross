import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/upload/data/dto/picked_audio_file_dto.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/picked_audio_file.dart';

void main() {
  group('PickedAudioFileDto', () {
    test('toEntity maps dto to PickedAudioFile correctly', () {
      const dto = PickedAudioFileDto(
        name: 'track.wav',
        extension: 'wav',
        sizeInBytes: 2048,
        path: '/storage/emulated/0/Download/track.wav',
      );

      final result = dto.toEntity();

      expect(
        result,
        const PickedAudioFile(
          name: 'track.wav',
          extension: 'wav',
          sizeInBytes: 2048,
          path: '/storage/emulated/0/Download/track.wav',
        ),
      );
    });
  });
}
