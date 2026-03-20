import 'dart:typed_data';

import '../entities/ProfileImageUploadResult.dart';

typedef UploadProgressCallback = void Function(int sent, int total);

abstract class ProfileRepository {
  Future<ProfileImageUploadResult> uploadProfileImage({
    required ProfileImageType type,
    required String fileName,
    required Uint8List fileBytes,
    required String mimeType,
    UploadProgressCallback? onProgress,
  });
}
