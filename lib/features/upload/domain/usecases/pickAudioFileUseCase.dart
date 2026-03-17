import '../entities/PickedAudioFile.dart';
import '../repositories/uploadRepository.dart';

class PickAudioFileUseCase {
  const PickAudioFileUseCase(this._uploadRepository);

  final UploadRepository _uploadRepository;

  Future<PickedAudioFile?> call() {
    return _uploadRepository.pickAudioFile();
  }
}
