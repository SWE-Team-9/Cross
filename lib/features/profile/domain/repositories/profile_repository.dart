import '../../../upload/domain/entities/managed_track.dart';
import '../entities/profile_entity.dart';
import '../entities/profile_page_data.dart';

abstract class ProfileRepository {
  Future<ProfileEntity> getProfile(String handle);
  Future<ProfileEntity> getMyProfile();
  Future<List<ManagedTrack>> getUserTracks(String userId);
  Future<List<ManagedTrack>> getUserLikedTracks(String userId);
  Future<List<ManagedTrack>> getUserRepostedTracks(String userId);
  Future<ProfilePageData> getProfilePage(String handle);
  Future<List<dynamic>> getUserPlaylists(String userId);
  Future<List<dynamic>> getUserLikedPlaylists(String userId);

  Future<ProfileEntity> updateProfile({
    String? displayName,
    String? bio,
    String? location,
    String? website,
    AccountTier? accountTier,
    List<String>? favoriteGenres,
    ProfileVisibility? visibility,
  });

  Future<Map<String, String>> updateExternalLinks({
    required Map<String, String> externalLinks,
  });

  Future<String> uploadProfileImage({
    required ProfileImageType imageType,
    required String filePath,
  });

  Future<bool> checkHandleAvailable(String handle);
}

enum ProfileImageType {
  AVATAR,
  COVER,
}
