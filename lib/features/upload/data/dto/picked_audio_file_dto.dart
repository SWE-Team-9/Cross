import '../../domain/entities/picked_audio_file.dart';

class PickedAudioFileDto {
  const PickedAudioFileDto({
    required this.name,
    required this.extension,
    required this.sizeInBytes,
    this.path,
  });

  final String name;
  final String extension;
  final int sizeInBytes;
  final String? path;

  PickedAudioFile toEntity() {
    return PickedAudioFile(
      name: name,
      extension: extension,
      sizeInBytes: sizeInBytes,
      path: path,
    );
  }
}
