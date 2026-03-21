import 'package:flutter_bloc/flutter_bloc.dart';

// Project
import '../../../../core/errors/failure.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import 'profile_state.dart';

/// Manages all state changes for the profile feature.
///
/// T2.3: loadProfile()   → GET /api/v1/profiles/:handle
/// T2.4: updateProfile() → PATCH /api/v1/profiles/me
/// T2.4: uploadImage()   → POST /api/v1/profiles/me/images/:type
class ProfileCubit extends Cubit<ProfileState> {
  final GetProfileUseCase _getProfileUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final ProfileRepository _profileRepository;

  ProfileCubit({
    required GetProfileUseCase getProfileUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required ProfileRepository profileRepository,
  })  : _getProfileUseCase = getProfileUseCase,
        _updateProfileUseCase = updateProfileUseCase,
        _profileRepository = profileRepository,
        super(ProfileInitial());

  // ── T2.3 ──────────────────────────────────────────────────────────────────

  /// Loads a user profile by handle.
  /// Called by ProfilePage on creation.
  Future<void> loadProfile(String handle) async {
    emit(ProfileLoading());

    try {
      final profile = await _getProfileUseCase(handle);
      emit(ProfileLoaded(profile));
    } on Failure catch (f) {
      // Failure thrown by ProfileRepositoryImpl._mapDioError()
      emit(ProfileError(f.message));
    }
  }

  // ── T2.4 ──────────────────────────────────────────────────────────────────

  /// Saves profile text field changes.
  /// Called by EditProfilePage after form validation passes.
  Future<void> updateProfile(UpdateProfileParams params) async {
    final currentState = state;
    // Guard: can only update if a profile is already loaded
    if (currentState is! ProfileLoaded) return;

    emit(ProfileUpdating(currentState.profile));

    try {
      final updatedProfile = await _updateProfileUseCase(params);
      emit(ProfileUpdateSuccess(updatedProfile));
    } on Failure catch (f) {
      // Stay on the edit page with the existing data — just show the error
      emit(ProfileUpdateError(currentState.profile, f.message));
    }
  }

  /// Uploads a new avatar or cover photo.
  /// Called by EditProfilePage after the user picks an image.
  Future<void> uploadImage({
    required ProfileImageType imageType,
    required String filePath,
  }) async {
    final currentState = state;
    if (currentState is! ProfileLoaded) return;

    emit(ProfileImageUploading(currentState.profile, imageType));

    try {
      final newUrl = await _profileRepository.uploadProfileImage(
        imageType: imageType,
        filePath: filePath,
      );

      // Update only the changed image URL — keep all other profile data.
      final updatedProfile = imageType == ProfileImageType.AVATAR
          ? currentState.profile.copyWith(avatarUrl: newUrl)
          : currentState.profile.copyWith(coverPhotoUrl: newUrl);

      emit(ProfileLoaded(updatedProfile));
    } on Failure catch (f) {
      // Upload failed — go back to showing the current profile unchanged
      emit(ProfileUpdateError(currentState.profile, f.message));
    }
  }
}
