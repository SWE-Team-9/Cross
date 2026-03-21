import '../entities/profile_entity.dart';
import '../repositories/profile_repository.dart';

/// Fetches a single user profile by handle.
/// Used by ProfilePage when it first loads.
///
/// On success: returns the ProfileEntity.
/// On failure: throws a Failure (caught by ProfileCubit).
class GetProfileUseCase {
  final ProfileRepository _repository;

  const GetProfileUseCase(this._repository);

  /// Called like a function: await getProfileUseCase(handle)
  Future<ProfileEntity> call(String handle) {
    return _repository.getProfile(handle);
  }
}
