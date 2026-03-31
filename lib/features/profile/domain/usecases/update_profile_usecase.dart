import '../entities/profile_entity.dart';
import '../repositories/profile_repository.dart';

class UpdateProfileParams {
  final String? displayName;
  final String? bio;
  final String? location;
  final String? website;
  final AccountTier? accountTier;
  final List<String>? favoriteGenres;
  final ProfileVisibility? visibility;
  final Map<String, String>? externalLinks;

  const UpdateProfileParams({
    this.displayName,
    this.bio,
    this.location,
    this.website,
    this.accountTier,
    this.favoriteGenres,
    this.visibility,
    this.externalLinks,
  });

  bool get hasBaseProfileChanges =>
      displayName != null ||
      bio != null ||
      location != null ||
      website != null ||
      accountTier != null ||
      favoriteGenres != null ||
      visibility != null;

  bool get hasExternalLinksChanges => externalLinks != null;
}

class UpdateProfileUseCase {
  final ProfileRepository _repository;

  const UpdateProfileUseCase(this._repository);

  Future<ProfileEntity> call(UpdateProfileParams params) {
    return _repository.updateProfile(
      displayName: params.displayName,
      bio: params.bio,
      location: params.location,
      website: params.website,
      accountTier: params.accountTier,
      favoriteGenres: params.favoriteGenres,
      visibility: params.visibility,
    );
  }
}