import 'dart:typed_data';

import '../entities/ProfileImageUploadResult.dart';
import '../repositories/profileRepository.dart';

class UploadProfileImageUseCase {
  const UploadProfileImageUseCase(this._profileRepository);

  final ProfileRepository _profileRepository;

  Future<ProfileImageUploadResult> call({
    required ProfileImageType type,
    required String fileName,
    required Uint8List fileBytes,
    required String mimeType,
    UploadProgressCallback? onProgress,
  }) {
    return _profileRepository.uploadProfileImage(
      type: type,
      fileName: fileName,
      fileBytes: fileBytes,
      mimeType: mimeType,
      onProgress: onProgress,
    );
  }
}
