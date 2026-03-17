import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/PickedAudioFile.dart';
import 'package:soundcloud_clone/features/upload/domain/repositories/uploadRepository.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/pickAudioFileUseCase.dart';

class MockUploadRepository extends Mock implements UploadRepository {}

void main() {
  late MockUploadRepository mockUploadRepository;
  late PickAudioFileUseCase useCase;

  const tPickedAudioFile = PickedAudioFile(
    name: 'test_audio.mp3',
    extension: 'mp3',
    sizeInBytes: 1024,
    path: '/storage/emulated/0/Download/test_audio.mp3',
  );

  setUp(() {
    mockUploadRepository = MockUploadRepository();
    useCase = PickAudioFileUseCase(mockUploadRepository);
  });

  group('PickAudioFileUseCase', () {
    test('should return PickedAudioFile when repository returns a file',
        () async {
      when(() => mockUploadRepository.pickAudioFile())
          .thenAnswer((_) async => tPickedAudioFile);

      final result = await useCase();

      expect(result, tPickedAudioFile);
      verify(() => mockUploadRepository.pickAudioFile()).called(1);
      verifyNoMoreInteractions(mockUploadRepository);
    });

    test('should return null when repository returns null', () async {
      when(() => mockUploadRepository.pickAudioFile())
          .thenAnswer((_) async => null);

      final result = await useCase();

      expect(result, isNull);
      verify(() => mockUploadRepository.pickAudioFile()).called(1);
      verifyNoMoreInteractions(mockUploadRepository);
    });
  });
}
