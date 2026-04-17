import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../interactions/domain/usecases/get_my_liked_tracks_usecase.dart';
import '../../../interactions/domain/usecases/get_my_reposted_tracks_usecase.dart';
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
  final GetMyLikedTracksUseCase _getMyLikedTracksUseCase;
  final GetMyRepostedTracksUseCase _getMyRepostedTracksUseCase;

  ProfileCubit({
    required GetProfileUseCase getProfileUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required ProfileRepository profileRepository,
    required GetMyLikedTracksUseCase getMyLikedTracksUseCase,
    required GetMyRepostedTracksUseCase getMyRepostedTracksUseCase,
  })  : _getProfileUseCase = getProfileUseCase,
        _updateProfileUseCase = updateProfileUseCase,
        _profileRepository = profileRepository,
        _getMyLikedTracksUseCase = getMyLikedTracksUseCase,
        _getMyRepostedTracksUseCase = getMyRepostedTracksUseCase,
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
      List<ManagedTrack> likedTracks = const <ManagedTrack>[];
      List<ManagedTrack> repostedTracks = const <ManagedTrack>[];

      try {
        tracks = await _profileRepository.getUserTracks('me').timeout(
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

      try {
        likedTracks = await _getMyLikedTracksUseCase().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw const ServerFailure(
              'Liked tracks request timed out. Please check your connection.',
            );
          },
        );
        // ignore: avoid_print
        print('LIKED TRACKS COUNT: ${likedTracks.length}');
      } catch (e) {
        // ignore: avoid_print
        print('LIKED TRACKS ERROR: $e');
        likedTracks = const <ManagedTrack>[];
      }

      try {
        repostedTracks = await _getMyRepostedTracksUseCase().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw const ServerFailure(
              'Reposted tracks request timed out. Please check your connection.',
            );
          },
        );
        // ignore: avoid_print
        print('REPOSTED TRACKS COUNT: ${repostedTracks.length}');
      } catch (e) {
        // ignore: avoid_print
        print('REPOSTED TRACKS ERROR: $e');
        repostedTracks = const <ManagedTrack>[];
      }
      emit(
        ProfileLoaded(
          profile,
          tracks: tracks,
          likedTracks: likedTracks,
          repostedTracks: repostedTracks,
        ),
      );
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
    final List<ManagedTrack> currentLikedTracks = _likedTracksFromState();
    final List<ManagedTrack> currentRepostedTracks = _repostedTracksFromState();

    if (!params.hasBaseProfileChanges && !params.hasExternalLinksChanges) {
      emit(
        ProfileLoaded(
          currentProfile,
          tracks: currentTracks,
          likedTracks: currentLikedTracks,
          repostedTracks: currentRepostedTracks,
        ),
      );
      return;
    }

    emit(
      ProfileUpdating(
        currentProfile,
        tracks: currentTracks,
        likedTracks: currentLikedTracks,
        repostedTracks: currentRepostedTracks,
      ),
    );

    try {
      ProfileEntity workingProfile = currentProfile;

      if (params.hasBaseProfileChanges) {
        final updatedProfile = await _updateProfileUseCase(params);
        workingProfile = updatedProfile.copyWith(
          followersCount: updatedProfile.followersCount == 0
              ? currentProfile.followersCount
              : updatedProfile.followersCount,
          followingCount: updatedProfile.followingCount == 0
              ? currentProfile.followingCount
              : updatedProfile.followingCount,
        );
      }

      if (params.hasExternalLinksChanges) {
        final updatedLinks = await _profileRepository.updateExternalLinks(
          externalLinks: params.externalLinks ?? {},
        );
        workingProfile = workingProfile.copyWith(externalLinks: updatedLinks);
      }

      if (params.favoriteGenres != null) {
        workingProfile = workingProfile.copyWith(
          favoriteGenres: List<String>.from(params.favoriteGenres!),
        );
      }

      emit(
        ProfileUpdateSuccess(
          workingProfile,
          tracks: currentTracks,
          likedTracks: currentLikedTracks,
          repostedTracks: currentRepostedTracks,
        ),
      );

      emit(
        ProfileLoaded(
          workingProfile,
          tracks: currentTracks,
          likedTracks: currentLikedTracks,
          repostedTracks: currentRepostedTracks,
        ),
      );
    } on Failure catch (failure) {
      emit(
        ProfileUpdateError(
          currentProfile,
          failure.message,
          tracks: currentTracks,
          likedTracks: currentLikedTracks,
          repostedTracks: currentRepostedTracks,
        ),
      );
    } catch (_) {
      emit(
        ProfileUpdateError(
          currentProfile,
          'Unable to update profile. Please try again.',
          tracks: currentTracks,
          likedTracks: currentLikedTracks,
          repostedTracks: currentRepostedTracks,
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
    final List<ManagedTrack> currentLikedTracks = _likedTracksFromState();
    final List<ManagedTrack> currentRepostedTracks = _repostedTracksFromState();

    emit(
      ProfileImageUploading(
        currentProfile,
        imageType,
        tracks: currentTracks,
        likedTracks: currentLikedTracks,
        repostedTracks: currentRepostedTracks,
      ),
    );

    try {
      final String newUrl = await _profileRepository.uploadProfileImage(
        imageType: imageType,
        filePath: filePath,
      );

      final ProfileEntity updatedProfile = imageType == ProfileImageType.AVATAR
          ? currentProfile.copyWith(avatarUrl: newUrl)
          : currentProfile.copyWith(coverPhotoUrl: newUrl);

      emit(
        ProfileLoaded(
          updatedProfile,
          tracks: currentTracks,
          likedTracks: currentLikedTracks,
          repostedTracks: currentRepostedTracks,
        ),
      );
    } on Failure catch (failure) {
      emit(
        ProfileImageUploadError(
          currentProfile,
          imageType: imageType,
          filePath: filePath,
          message: failure.message,
          tracks: currentTracks,
          likedTracks: currentLikedTracks,
          repostedTracks: currentRepostedTracks,
        ),
      );
    } catch (_) {
      emit(
        ProfileImageUploadError(
          currentProfile,
          imageType: imageType,
          filePath: filePath,
          message: 'Unable to upload image. Please try again.',
          tracks: currentTracks,
          likedTracks: currentLikedTracks,
          repostedTracks: currentRepostedTracks,
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
    if (currentState is ProfileImageUploadError) {
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
    if (currentState is ProfileUpdating) {
      return currentState.tracks;
    }
    if (currentState is ProfileUpdateSuccess) {
      return currentState.tracks;
    }
    if (currentState is ProfileUpdateError) {
      return currentState.tracks;
    }
    if (currentState is ProfileImageUploading) {
      return currentState.tracks;
    }
    if (currentState is ProfileImageUploadError) {
      return currentState.tracks;
    }

    return const <ManagedTrack>[];
  }

  List<ManagedTrack> _likedTracksFromState() {
    final currentState = state;

    if (currentState is ProfileLoaded) {
      return currentState.likedTracks;
    }
    if (currentState is ProfileUpdating) {
      return currentState.likedTracks;
    }
    if (currentState is ProfileUpdateSuccess) {
      return currentState.likedTracks;
    }
    if (currentState is ProfileUpdateError) {
      return currentState.likedTracks;
    }
    if (currentState is ProfileImageUploading) {
      return currentState.likedTracks;
    }
    if (currentState is ProfileImageUploadError) {
      return currentState.likedTracks;
    }

    return const <ManagedTrack>[];
  }

  List<ManagedTrack> _repostedTracksFromState() {
    final currentState = state;

    if (currentState is ProfileLoaded) {
      return currentState.repostedTracks;
    }
    if (currentState is ProfileUpdating) {
      return currentState.repostedTracks;
    }
    if (currentState is ProfileUpdateSuccess) {
      return currentState.repostedTracks;
    }
    if (currentState is ProfileUpdateError) {
      return currentState.repostedTracks;
    }
    if (currentState is ProfileImageUploading) {
      return currentState.repostedTracks;
    }
    if (currentState is ProfileImageUploadError) {
      return currentState.repostedTracks;
    }

    return const <ManagedTrack>[];
  }
}
