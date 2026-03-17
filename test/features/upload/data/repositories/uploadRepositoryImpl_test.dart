import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/upload/data/datasources/audioFilePickerDataSource.dart';
import 'package:soundcloud_clone/features/upload/data/dto/PickedAudioFileDto.dart';
import 'package:soundcloud_clone/features/upload/data/repositories/uploadRepositoryImpl.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/PickedAudioFile.dart';

class MockAudioFilePickerDataSource extends Mock
    implements AudioFilePickerDataSource {}

void main() {
  late MockAudioFilePickerDataSource mockAudioFilePickerDataSource;
  late UploadRepositoryImpl repository;

  const tPickedAudioFileDto = PickedAudioFileDto(
    name: 'test_audio.wav',
    extension: 'wav',
    sizeInBytes: 2048,
    path: '/storage/emulated/0/Download/test_audio.wav',
  );

  const tPickedAudioFile = PickedAudioFile(
    name: 'test_audio.wav',
    extension: 'wav',
    sizeInBytes: 2048,
    path: '/storage/emulated/0/Download/test_audio.wav',
  );

  setUp(() {
    mockAudioFilePickerDataSource = MockAudioFilePickerDataSource();
    repository = UploadRepositoryImpl(mockAudioFilePickerDataSource);
  });

  group('UploadRepositoryImpl', () {
    test('should return mapped PickedAudioFile when datasource returns dto',
        () async {
      when(() => mockAudioFilePickerDataSource.pickAudioFile())
          .thenAnswer((_) async => tPickedAudioFileDto);

      final result = await repository.pickAudioFile();

      expect(result, isA<PickedAudioFile>());
      expect(result?.name, tPickedAudioFile.name);
      expect(result?.extension, tPickedAudioFile.extension);
      expect(result?.sizeInBytes, tPickedAudioFile.sizeInBytes);
      expect(result?.path, tPickedAudioFile.path);

      verify(() => mockAudioFilePickerDataSource.pickAudioFile()).called(1);
      verifyNoMoreInteractions(mockAudioFilePickerDataSource);
    });

    test('should return null when datasource returns null', () async {
      when(() => mockAudioFilePickerDataSource.pickAudioFile())
          .thenAnswer((_) async => null);

      final result = await repository.pickAudioFile();

      expect(result, isNull);
      verify(() => mockAudioFilePickerDataSource.pickAudioFile()).called(1);
      verifyNoMoreInteractions(mockAudioFilePickerDataSource);
    });

    test('should rethrow when datasource throws', () async {
      when(() => mockAudioFilePickerDataSource.pickAudioFile())
          .thenThrow(Exception('picker failed'));

      expect(
        () => repository.pickAudioFile(),
        throwsA(isA<Exception>()),
      );

      verify(() => mockAudioFilePickerDataSource.pickAudioFile()).called(1);
      verifyNoMoreInteractions(mockAudioFilePickerDataSource);
    });
  });
}
