import 'package:equatable/equatable.dart';

class PickedImageFile extends Equatable {
  const PickedImageFile({
    required this.name,
    required this.extension,
    required this.sizeInBytes,
    required this.path,
  });

  final String name;
  final String extension;
  final int sizeInBytes;
  final String path;

  String get formattedSize {
    if (sizeInBytes < 1024) {
      return '$sizeInBytes B';
    }

    if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    }

    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  List<Object?> get props => [
        name,
        extension,
        sizeInBytes,
        path,
      ];
}
