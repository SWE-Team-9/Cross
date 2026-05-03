import '../../../upload/domain/entities/managed_track.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/entities/profile_page_data.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';
import '../dto/profile_dto.dart';
import '../../../playlists/data/dto/playlist_dto.dart';

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
  Future<List<ManagedTrack>> getUserTracks(String userId) async {
    final dtos = await _remoteDataSource.getUserTracks(userId);
    return dtos.map((dto) => dto.toEntity()).toList(growable: false);
  }

  @override
  Future<List<ManagedTrack>> getUserLikedTracks(String userId) async {
    final dtos = await _remoteDataSource.getUserLikedTracks(userId);
    return dtos.map((dto) => dto.toEntity()).toList(growable: false);
  }

  @override
  Future<List<ManagedTrack>> getUserRepostedTracks(String userId) async {
    final dtos = await _remoteDataSource.getUserRepostedTracks(userId);
    return dtos.map((dto) => dto.toEntity()).toList(growable: false);
  }

  @override
  Future<ProfilePageData> getProfilePage(String handle) async {
    final dto = await _remoteDataSource.getProfilePage(handle);
    return dto.toEntity();
  }

  @override
  Future<List<dynamic>> getUserPlaylists(String userId) async {
    return _remoteDataSource.getUserPlaylists(userId);
  }

  @override
  Future<List<dynamic>> getUserLikedPlaylists(String userId) async {
    return _remoteDataSource.getUserLikedPlaylists(userId);
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
