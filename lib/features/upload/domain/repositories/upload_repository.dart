import '../entities/picked_audio_file.dart';
import '../entities/picked_image_file.dart';

typedef UploadProgressCallback = void Function(double progress);

class UploadTrackResult {
  const UploadTrackResult({
    required this.trackId,
    required this.status,
    this.secretToken,
  });

  final String trackId;
  final String status;
  final String? secretToken;
}

abstract class UploadRepository {
  Future<PickedAudioFile?> pickAudioFile();

  Future<UploadTrackResult> uploadTrack({
    required PickedAudioFile file,
    required String title,
    PickedImageFile? coverArt,
    String? genre,
    String? description,
    DateTime? releaseDate,
    List<String> tags = const <String>[],
    UploadProgressCallback? onProgress,
  });

  Future<String> getTrackStatus({
    required String trackId,
  });
}
