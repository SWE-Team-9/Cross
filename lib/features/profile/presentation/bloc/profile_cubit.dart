import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../upload/domain/entities/managed_track.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import 'profile_state.dart';

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

  Future<void> loadProfile(String handle) async {
    emit(ProfileLoading());

    try {
      final profile = await _getProfileUseCase(handle).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw const ServerFailure(
            'Request timed out. Please check your connection.',
          );
        },
      );

      emit(ProfileLoaded(profile));
    } on Failure catch (failure) {
      emit(ProfileError(failure.message));
    } catch (_) {
      emit(ProfileError('Something went wrong. Please try again.'));
    }
  }

  Future<void> loadOwnProfile() async {
    emit(ProfileLoading());

    try {
      final profile = await _profileRepository.getMyProfile().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw const ServerFailure(
            'Request timed out. Please check your connection.',
          );
        },
      );

      List<ManagedTrack> tracks = const <ManagedTrack>[];
      try {
        tracks = await _profileRepository.getUserTracks(profile.id).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw const ServerFailure(
              'Request timed out. Please check your connection.',
            );
          },
        );
      } catch (_) {
        tracks = const <ManagedTrack>[];
      }

      emit(ProfileLoaded(profile, tracks: tracks));
    } on Failure catch (failure) {
      emit(ProfileError(failure.message));
    } catch (_) {
      emit(ProfileError('Something went wrong. Please try again.'));
    }
  }

  Future<void> updateProfile(UpdateProfileParams params) async {
    final ProfileEntity? currentProfile = _currentProfileFromState();
    if (currentProfile == null) return;

    final List<ManagedTrack> currentTracks = _tracksFromState();

    if (!params.hasBaseProfileChanges && !params.hasExternalLinksChanges) {
      emit(ProfileLoaded(currentProfile, tracks: currentTracks));
      return;
    }

    emit(ProfileUpdating(currentProfile));

    try {
      ProfileEntity workingProfile = currentProfile;

      if (params.hasBaseProfileChanges) {
        workingProfile = await _updateProfileUseCase(params);
      }

      if (params.hasExternalLinksChanges) {
        final updatedLinks = await _profileRepository.updateExternalLinks(
          externalLinks: params.externalLinks ?? {},
        );
        workingProfile = workingProfile.copyWith(externalLinks: updatedLinks);
      }

      emit(ProfileUpdateSuccess(workingProfile));
      emit(ProfileLoaded(workingProfile, tracks: currentTracks));
    } on Failure catch (failure) {
      emit(ProfileUpdateError(currentProfile, failure.message));
    } catch (_) {
      emit(
        ProfileUpdateError(
          currentProfile,
          'Unable to update profile. Please try again.',
        ),
      );
    }
  }

  Future<void> uploadImage({
    required ProfileImageType imageType,
    required String filePath,
  }) async {
    final ProfileEntity? currentProfile = _currentProfileFromState();
    if (currentProfile == null) return;

    final List<ManagedTrack> currentTracks = _tracksFromState();

    emit(ProfileImageUploading(currentProfile, imageType));

    try {
      final String newUrl = await _profileRepository.uploadProfileImage(
        imageType: imageType,
        filePath: filePath,
      );

      final ProfileEntity updatedProfile = imageType == ProfileImageType.AVATAR
          ? currentProfile.copyWith(avatarUrl: newUrl)
          : currentProfile.copyWith(coverPhotoUrl: newUrl);

      emit(ProfileLoaded(updatedProfile, tracks: currentTracks));
    } on Failure catch (failure) {
      emit(ProfileUpdateError(currentProfile, failure.message));
    } catch (_) {
      emit(
        ProfileUpdateError(
          currentProfile,
          'Unable to upload image. Please try again.',
        ),
      );
    }
  }

  ProfileEntity? _currentProfileFromState() {
    final currentState = state;

    if (currentState is ProfileLoaded) {
      return currentState.profile;
    }
    if (currentState is ProfileUpdating) {
      return currentState.currentProfile;
    }
    if (currentState is ProfileUpdateError) {
      return currentState.currentProfile;
    }
    if (currentState is ProfileImageUploading) {
      return currentState.currentProfile;
    }
    if (currentState is ProfileUpdateSuccess) {
      return currentState.updatedProfile;
    }

    return null;
  }

  List<ManagedTrack> _tracksFromState() {
    final currentState = state;

    if (currentState is ProfileLoaded) {
      return currentState.tracks;
    }

    return const <ManagedTrack>[];
  }
}
