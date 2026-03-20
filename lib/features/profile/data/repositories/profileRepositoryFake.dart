import 'dart:typed_data';

import '../../domain/entities/ProfileImageUploadResult.dart';
import '../../domain/repositories/profileRepository.dart';

enum MockProfileImageUploadMode {
  success,
  alwaysFail,
  failOnce,
}

class ProfileRepositoryFake implements ProfileRepository {
  ProfileRepositoryFake({
    this.mode = MockProfileImageUploadMode.success,
  });

  final MockProfileImageUploadMode mode;

  bool _hasFailedOnce = false;

  @override
  Future<ProfileImageUploadResult> uploadProfileImage({
    required ProfileImageType type,
    required String fileName,
    required Uint8List fileBytes,
    required String mimeType,
    UploadProgressCallback? onProgress,
  }) async {
    const int totalBytes = 100;

    for (final sentBytes in <int>[15, 35, 60, 85, 100]) {
      await Future.delayed(const Duration(milliseconds: 250));
      onProgress?.call(sentBytes, totalBytes);
    }

    await Future.delayed(const Duration(milliseconds: 400));

    switch (mode) {
      case MockProfileImageUploadMode.success:
        break;

      case MockProfileImageUploadMode.alwaysFail:
        throw Exception('Mock upload failed. Please try again.');

      case MockProfileImageUploadMode.failOnce:
        if (!_hasFailedOnce) {
          _hasFailedOnce = true;
          throw Exception('Mock upload failed once. Please retry.');
        }
        break;
    }

    return ProfileImageUploadResult(
      type: type,
      url: 'mock://${type.endpointSegment}/$fileName',
      key:
          'mock_${type.endpointSegment}_${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}
