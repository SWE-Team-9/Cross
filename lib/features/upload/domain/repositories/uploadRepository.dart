import '../entities/PickedAudioFile.dart';

abstract class UploadRepository {
  Future<PickedAudioFile?> pickAudioFile();
}