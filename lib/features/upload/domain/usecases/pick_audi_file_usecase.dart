import '../entities/picked_audio_file.dart';
import '../repositories/upload_repository.dart';

class PickAudioFileUseCase {
  const PickAudioFileUseCase(this._uploadRepository);

  final UploadRepository _uploadRepository;

  Future<PickedAudioFile?> call() {
    return _uploadRepository.pickAudioFile();
  }
}
