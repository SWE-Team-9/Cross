import '../entities/PickedAudioFile.dart';

class UploadTrackResult {
  const UploadTrackResult({
    required this.trackId,
    required this.status,
  });

  final String trackId;
  final String status;
}

abstract class UploadRepository {
  Future<PickedAudioFile?> pickAudioFile();

  Future<UploadTrackResult> uploadTrack({
    required PickedAudioFile file,
    required String title,
    String? genre,
  });

  Future<String> getTrackStatus({
    required String trackId,
  });
}