import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  const ProfileRepositoryImpl(this._remoteDataSource);

  @override
  Future<ProfileEntity> getProfile(String handle) async {
    final dto = await _remoteDataSource.getProfile(handle);
    return dto.toEntity();
  }

  @override
  Future<ProfileEntity> getMyProfile() async {
    final dto = await _remoteDataSource.getMyProfile();
    return dto.toEntity();
  }

  @override
  Future<ProfileEntity> updateProfile({
    String? displayName,
    String? bio,
    String? location,
    String? website,
    AccountTier? accountTier,
    List<String>? favoriteGenres,
    ProfileVisibility? visibility,
  }) async {
    final body = <String, dynamic>{};

    if (displayName != null) body['display_name'] = displayName;
    if (bio != null) body['bio'] = bio;
    if (location != null) body['location'] = location;
    if (website != null) body['website'] = website;
    if (favoriteGenres != null) body['favorite_genres'] = favoriteGenres;
    if (visibility != null) {
      body['is_private'] = visibility == ProfileVisibility.PRIVATE;
    }
    if (accountTier != null) {
      body['account_type'] =
          accountTier == AccountTier.ARTIST ? 'ARTIST' : 'LISTENER';
    }

    final dto = await _remoteDataSource.updateProfile(body);
    return dto.toEntity();
  }

  @override
  Future<Map<String, String>> updateExternalLinks({
    required Map<String, String> externalLinks,
  }) {
    return _remoteDataSource.updateExternalLinks(externalLinks);
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