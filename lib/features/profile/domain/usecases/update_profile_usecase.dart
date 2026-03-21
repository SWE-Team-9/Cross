// Dart SDK
// Flutter
// Third-party
// Project
import '../entities/profile_entity.dart';
import '../repositories/profile_repository.dart';

/// Parameters for UpdateProfileUseCase.
/// All fields are optional — only changed fields are sent to the API.
/// Style: PascalCase class, camelCase fields.
class UpdateProfileParams {
  final String? displayName;
  final String? bio;
  final String? location;
  final List<String>? favoriteGenres;
  final ProfileVisibility? visibility;

  const UpdateProfileParams({
    this.displayName,
    this.bio,
    this.location,
    this.favoriteGenres,
    this.visibility,
  });
}

/// Saves changes to the current user's profile.
/// Used by EditProfilePage when the user taps Save.
///
/// On success: returns the updated ProfileEntity.
/// On failure: throws a Failure (caught by ProfileCubit).
class UpdateProfileUseCase {
  final ProfileRepository _repository;

  const UpdateProfileUseCase(this._repository);

  Future<ProfileEntity> call(UpdateProfileParams params) {
    return _repository.updateProfile(
      displayName: params.displayName,
      bio: params.bio,
      location: params.location,
      favoriteGenres: params.favoriteGenres,
      visibility: params.visibility,
    );
  }
}
