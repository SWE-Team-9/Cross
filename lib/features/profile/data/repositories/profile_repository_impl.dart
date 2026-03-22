// Dart SDK
// Flutter
// Third-party
// Project
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  const ProfileRepositoryImpl(this._remoteDataSource);

  @override
  Future<ProfileEntity> getProfile(String handle) async {
    // DioClient already maps DioException → Failure, so we let
    // any Failure thrown here bubble up to the Cubit unchanged.
    final dto = await _remoteDataSource.getProfile(handle);
    return dto.toEntity();
  }

  @override
  Future<ProfileEntity> updateProfile({
    String? displayName,
    String? bio,
    String? location,
    List<String>? favoriteGenres,
    ProfileVisibility? visibility,
  }) async {
    // Build partial update body — only include fields the user changed.
    // Sending null fields could accidentally clear data on the server.
    final body = <String, dynamic>{};
    if (displayName != null) body['display_name'] = displayName;
    if (bio != null) body['bio'] = bio;
    if (location != null) body['location'] = location;
    if (favoriteGenres != null) body['favorite_genres'] = favoriteGenres;
    if (visibility != null) {
      body['visibility'] =
          visibility == ProfileVisibility.PUBLIC ? 'PUBLIC' : 'PRIVATE';
    }

    final dto = await _remoteDataSource.updateProfile(body);
    return dto.toEntity();
  }

  @override
  Future<String> uploadProfileImage({
    required ProfileImageType imageType,
    required String filePath,
  }) async {
    return _remoteDataSource.uploadProfileImage(
      imageType: imageType,
      filePath: filePath,
    );
  }

  @override
  Future<bool> checkHandleAvailable(String handle) async {
    return _remoteDataSource.checkHandleAvailable(handle);
  }
}
