import 'package:file_picker/file_picker.dart';

import '../../../../core/errors/upload_picker_exceptions.dart';
import '../dto/picked_audio_file_dto.dart';
import '../services/audio_picker_permission_service.dart';

abstract class AudioFilePickerDataSource {
  Future<PickedAudioFileDto?> pickAudioFile();
}

class AudioFilePickerDataSourceImpl implements AudioFilePickerDataSource {
  AudioFilePickerDataSourceImpl(this._permissionService);

  final AudioPickerPermissionService _permissionService;
  static const List<String> _supportedExtensions = [
    'mp3',
    'wav',
    'flac',
    'aiff',
    'm4a',
    'aac',
    'ogg',
  ];

  @override
  Future<PickedAudioFileDto?> pickAudioFile() async {
    try {
      await _permissionService.ensurePermissionGranted();

      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _supportedExtensions,
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
        throw Exception(
          'Unsupported audio format. Allowed: ${_supportedExtensions.join(', ').toUpperCase()}.',
        );
      }

      return PickedAudioFileDto(
        name: file.name,
        extension: extension,
        sizeInBytes: file.size,
        path: file.path,
      );
    } on UploadPickerPermissionPermanentlyDeniedException {
      rethrow;
    } catch (error) {
      final String message = error.toString().replaceFirst('Exception: ', '');

      throw Exception('Failed to pick audio file: $message');
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
    return _supportedExtensions.contains(extension.toLowerCase());
  }
}
