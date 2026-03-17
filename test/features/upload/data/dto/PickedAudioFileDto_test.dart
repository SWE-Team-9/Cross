import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/upload/data/dto/PickedAudioFileDto.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/PickedAudioFile.dart';

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