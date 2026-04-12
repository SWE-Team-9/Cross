import '../../../upload/domain/entities/managed_track.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final ProfileEntity profile;
  final List<ManagedTrack> tracks;

  ProfileLoaded(
    this.profile, {
    this.tracks = const <ManagedTrack>[],
  });
}

class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}

class ProfileUpdating extends ProfileState {
  final ProfileEntity currentProfile;
  ProfileUpdating(this.currentProfile);
}

class ProfileUpdateSuccess extends ProfileState {
  final ProfileEntity updatedProfile;
  ProfileUpdateSuccess(this.updatedProfile);
}

class ProfileUpdateError extends ProfileState {
  final ProfileEntity currentProfile;
  final String message;
  ProfileUpdateError(this.currentProfile, this.message);
}

class ProfileImageUploading extends ProfileState {
  final ProfileEntity currentProfile;
  final ProfileImageType imageType;
  final List<ManagedTrack> tracks;

  ProfileImageUploading(
    this.currentProfile,
    this.imageType, {
    this.tracks = const <ManagedTrack>[],
  });
}

class ProfileImageUploadError extends ProfileState {
  final ProfileEntity currentProfile;
  final ProfileImageType imageType;
  final String filePath;
  final String message;
  final List<ManagedTrack> tracks;

  ProfileImageUploadError(
    this.currentProfile, {
    required this.imageType,
    required this.filePath,
    required this.message,
    this.tracks = const <ManagedTrack>[],
  });
}
