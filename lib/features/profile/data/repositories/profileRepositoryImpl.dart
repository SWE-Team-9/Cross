import 'dart:typed_data';

import '../../domain/entities/ProfileImageUploadResult.dart';
import '../../domain/repositories/profileRepository.dart';
import '../datasources/profileRemoteDataSource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._profileRemoteDataSource);

  final ProfileRemoteDataSource _profileRemoteDataSource;

  @override
  Future<ProfileImageUploadResult> uploadProfileImage({
    required ProfileImageType type,
    required String fileName,
    required Uint8List fileBytes,
    required String mimeType,
    UploadProgressCallback? onProgress,
  }) async {
    final dto = await _profileRemoteDataSource.uploadProfileImage(
      type: type,
      fileName: fileName,
      fileBytes: fileBytes,
      mimeType: mimeType,
      onProgress: onProgress,
    );

    return dto.toEntity(type);
  }
}
