import '../../domain/entities/PickedAudioFile.dart';
import '../../domain/repositories/uploadRepository.dart';
import '../datasources/audioFilePickerDataSource.dart';

class UploadRepositoryImpl implements UploadRepository {
  const UploadRepositoryImpl(this._audioFilePickerDataSource);

  final AudioFilePickerDataSource _audioFilePickerDataSource;

  @override
  Future<PickedAudioFile?> pickAudioFile() async {
    final result = await _audioFilePickerDataSource.pickAudioFile();
    return result?.toEntity();
  }
}
