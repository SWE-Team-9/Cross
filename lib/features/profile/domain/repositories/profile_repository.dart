import '../entities/profile_entity.dart';

abstract class ProfileRepository {
  Future<ProfileEntity> getProfile(String handle);
  Future<ProfileEntity> getMyProfile();

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
