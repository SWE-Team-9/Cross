import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../dto/PickedAudioFileDto.dart';

abstract class AudioFilePickerDataSource {
  Future<PickedAudioFileDto?> pickAudioFile();
}

class AudioFilePickerDataSourceImpl implements AudioFilePickerDataSource {
  const AudioFilePickerDataSourceImpl();

  @override
  Future<PickedAudioFileDto?> pickAudioFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['mp3', 'wav'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final PlatformFile file = result.files.single;

      final String extension = _resolveExtension(
        file.extension,
        file.name,
      );

      if (!_isSupportedExtension(extension)) {
        throw Exception('Only MP3 and WAV files are allowed.');
      }

      return PickedAudioFileDto(
        name: file.name,
        extension: extension,
        sizeInBytes: file.size,
        path: file.path,
      );
    } catch (error) {
      throw Exception('Failed to pick audio file: $error');
    }
  }

  String _resolveExtension(
    String? pickerExtension,
    String fileName,
  ) {
    final String normalizedPickerExtension =
        (pickerExtension ?? '').trim().toLowerCase();

    if (normalizedPickerExtension.isNotEmpty) {
      return normalizedPickerExtension;
    }

    final List<String> parts = fileName.split('.');

    if (parts.length < 2) {
      return '';
    }

    return parts.last.trim().toLowerCase();
  }

  bool _isSupportedExtension(String extension) {
    return extension == 'mp3' || extension == 'wav';
  }
}
