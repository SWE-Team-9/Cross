// Project
import '../../../../core/errors/failure.dart';
import '../entities/profile_entity.dart';

/// Abstract contract for all profile data operations.
abstract class ProfileRepository {
  /// Fetches a user profile by their handle.
  /// Throws a [Failure] if the request fails.
  Future<ProfileEntity> getProfile(String handle);

  /// Updates the current user's own profile fields.
  /// Throws a [Failure] if the update fails.
  Future<ProfileEntity> updateProfile({
    String? displayName,
    String? bio,
    String? location,
    List<String>? favoriteGenres,
    ProfileVisibility? visibility,
  });

  /// Uploads an avatar or cover photo image.
  /// Throws a [Failure] if the upload fails.
  Future<String> uploadProfileImage({
    required ProfileImageType imageType,
    required String filePath,
  });

  /// Checks if a handle is available.
  /// Throws a [Failure] if the server cannot be reached.
  Future<bool> checkHandleAvailable(String handle);
}

enum ProfileImageType {
  AVATAR,
  COVER,
}
