import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../playlists/domain/entities/playlist_entity.dart';
import '../../../playlists/data/dto/playlist_dto.dart';
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
      ProfileEntity profile;
      List<PlaylistEntity> playlists = const <PlaylistEntity>[];
      List<PlaylistEntity> likedPlaylists = const <PlaylistEntity>[];

      try {
        final profilePage =
            await _profileRepository.getProfilePage(handle).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw const ServerFailure(
              'Request timed out. Please check your connection.',
            );
          },
        );

        profile = profilePage.profile;
        playlists = profilePage.playlists;
        likedPlaylists = profilePage.likedPlaylists;

        // Fallback to legacy profile endpoint if aggregate profile is incomplete.
        if (profile.id.trim().isEmpty || profile.handle.trim().isEmpty) {
          throw const FormatException('Incomplete aggregate profile payload');
        }
      } catch (_) {
        profile = await _getProfileUseCase(handle).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw const ServerFailure(
              'Request timed out. Please check your connection.',
            );
          },
        );
        playlists = const <PlaylistEntity>[];
        likedPlaylists = const <PlaylistEntity>[];
      }

      List<ManagedTrack> tracks = const <ManagedTrack>[];
      List<ManagedTrack> likedTracks = const <ManagedTrack>[];
      List<ManagedTrack> repostedTracks = const <ManagedTrack>[];

      // Fetch user playlists if not obtained from aggregate endpoint
      if (playlists.isEmpty) {
        try {
          final rawPlaylists =
              await _profileRepository.getUserPlaylists(profile.id).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw const ServerFailure(
                'User playlists request timed out. Please check your connection.',
              );
            },
          );
          print('DEBUG: rawPlaylists = $rawPlaylists, type = ${rawPlaylists.runtimeType}');
          playlists = (rawPlaylists as List?)
                  ?.whereType<Map>()
                  .map((item) {
                    print('DEBUG: parsing playlist item = $item');
                    return PlaylistDto.fromJson(
                        Map<String, dynamic>.from(item as Map));
                  })
                  .map((dto) => dto.toEntity())
                  .toList(growable: false) ??
              const <PlaylistEntity>[];
          print('DEBUG: parsed playlists = $playlists, count = ${playlists.length}');
        } catch (e, st) {
          print('DEBUG: Error fetching user playlists: $e\n$st');
          playlists = const <PlaylistEntity>[];
        }
      } else {
        print('DEBUG: playlists already populated from aggregate endpoint, count = ${playlists.length}');
      }

      // Fetch user liked playlists if not obtained from aggregate endpoint
      if (likedPlaylists.isEmpty) {
        try {
          final rawLikedPlaylists =
              await _profileRepository.getUserLikedPlaylists(profile.id).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw const ServerFailure(
                'Liked playlists request timed out. Please check your connection.',
              );
            },
          );
          print('DEBUG: rawLikedPlaylists = $rawLikedPlaylists, type = ${rawLikedPlaylists.runtimeType}');
          likedPlaylists = (rawLikedPlaylists as List?)
                  ?.whereType<Map>()
                  .map((item) {
                    print('DEBUG: parsing liked playlist item = $item');
                    return PlaylistDto.fromJson(
                        Map<String, dynamic>.from(item as Map));
                  })
                  .map((dto) => dto.toEntity())
                  .toList(growable: false) ??
              const <PlaylistEntity>[];
          print('DEBUG: parsed likedPlaylists = $likedPlaylists, count = ${likedPlaylists.length}');
        } catch (e, st) {
          print('DEBUG: Error fetching user liked playlists: $e\n$st');
          likedPlaylists = const <PlaylistEntity>[];
        }
      } else {
        print('DEBUG: likedPlaylists already populated from aggregate endpoint, count = ${likedPlaylists.length}');
      }

      try {
        tracks = await _profileRepository.getUserTracks(profile.id).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw const ServerFailure(
              'Tracks request timed out. Please check your connection.',
            );
          },
        );
      } catch (_) {
        tracks = const <ManagedTrack>[];
      }

      try {
        likedTracks = await _profileRepository.getUserLikedTracks(profile.id).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw const ServerFailure(
              'Liked tracks request timed out. Please check your connection.',
            );
          },
        );
      } catch (_) {
        likedTracks = const <ManagedTrack>[];
      }

      try {
        repostedTracks = await _profileRepository.getUserRepostedTracks(profile.id).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw const ServerFailure(
              'Reposted tracks request timed out. Please check your connection.',
            );
          },
        );
      } catch (_) {
        repostedTracks = const <ManagedTrack>[];
      }

      emit(
        ProfileLoaded(
          profile,
          tracks: tracks,
          likedTracks: likedTracks,
          repostedTracks: repostedTracks,
          playlists: playlists,
          likedPlaylists: likedPlaylists,
        ),
      );
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

      try {
        likedTracks = await _getMyLikedTracksUseCase().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw const ServerFailure(
              'Liked tracks request timed out. Please check your connection.',
            );
          },
        );
      } catch (e) {
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
      } catch (e) {
        repostedTracks = const <ManagedTrack>[];
      }
      emit(
        ProfileLoaded(
          profile,
          tracks: tracks,
          likedTracks: likedTracks,
          repostedTracks: repostedTracks,
          playlists: const <PlaylistEntity>[],
          likedPlaylists: const <PlaylistEntity>[],
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
          playlists: _playlistsFromState(),
          likedPlaylists: _likedPlaylistsFromState(),
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
          playlists: _playlistsFromState(),
          likedPlaylists: _likedPlaylistsFromState(),
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
          playlists: _playlistsFromState(),
          likedPlaylists: _likedPlaylistsFromState(),
        ),
      );

      emit(
        ProfileLoaded(
          workingProfile,
          tracks: currentTracks,
          likedTracks: currentLikedTracks,
          repostedTracks: currentRepostedTracks,
          playlists: _playlistsFromState(),
          likedPlaylists: _likedPlaylistsFromState(),
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
          playlists: _playlistsFromState(),
          likedPlaylists: _likedPlaylistsFromState(),
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
          playlists: _playlistsFromState(),
          likedPlaylists: _likedPlaylistsFromState(),
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
          playlists: _playlistsFromState(),
          likedPlaylists: _likedPlaylistsFromState(),
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
          playlists: _playlistsFromState(),
          likedPlaylists: _likedPlaylistsFromState(),
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
          playlists: _playlistsFromState(),
          likedPlaylists: _likedPlaylistsFromState(),
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
          playlists: _playlistsFromState(),
          likedPlaylists: _likedPlaylistsFromState(),
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

  List<PlaylistEntity> _playlistsFromState() {
    final currentState = state;

    if (currentState is ProfileLoaded) {
      return currentState.playlists;
    }
    if (currentState is ProfileUpdating) {
      return currentState.playlists;
    }
    if (currentState is ProfileUpdateSuccess) {
      return currentState.playlists;
    }
    if (currentState is ProfileUpdateError) {
      return currentState.playlists;
    }
    if (currentState is ProfileImageUploading) {
      return currentState.playlists;
    }
    if (currentState is ProfileImageUploadError) {
      return currentState.playlists;
    }

    return const <PlaylistEntity>[];
  }

  List<PlaylistEntity> _likedPlaylistsFromState() {
    final currentState = state;

    if (currentState is ProfileLoaded) {
      return currentState.likedPlaylists;
    }
    if (currentState is ProfileUpdating) {
      return currentState.likedPlaylists;
    }
    if (currentState is ProfileUpdateSuccess) {
      return currentState.likedPlaylists;
    }
    if (currentState is ProfileUpdateError) {
      return currentState.likedPlaylists;
    }
    if (currentState is ProfileImageUploading) {
      return currentState.likedPlaylists;
    }
    if (currentState is ProfileImageUploadError) {
      return currentState.likedPlaylists;
    }

    return const <PlaylistEntity>[];
  }
}
