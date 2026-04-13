import '../../../upload/domain/entities/managed_track.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final ProfileEntity profile;
  final List<ManagedTrack> tracks;
  final List<ManagedTrack> likedTracks;
  final List<ManagedTrack> repostedTracks;

  ProfileLoaded(
    this.profile, {
    this.tracks = const <ManagedTrack>[],
    this.likedTracks = const <ManagedTrack>[],
    this.repostedTracks = const <ManagedTrack>[],
  });
}

class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}

class ProfileUpdating extends ProfileState {
  final ProfileEntity currentProfile;
  final List<ManagedTrack> tracks;
  final List<ManagedTrack> likedTracks;
  final List<ManagedTrack> repostedTracks;

  ProfileUpdating(
    this.currentProfile, {
    this.tracks = const <ManagedTrack>[],
    this.likedTracks = const <ManagedTrack>[],
    this.repostedTracks = const <ManagedTrack>[],
  });
}

class ProfileUpdateSuccess extends ProfileState {
  final ProfileEntity updatedProfile;
  final List<ManagedTrack> tracks;
  final List<ManagedTrack> likedTracks;
  final List<ManagedTrack> repostedTracks;

  ProfileUpdateSuccess(
    this.updatedProfile, {
    this.tracks = const <ManagedTrack>[],
    this.likedTracks = const <ManagedTrack>[],
    this.repostedTracks = const <ManagedTrack>[],
  });
}

class ProfileUpdateError extends ProfileState {
  final ProfileEntity currentProfile;
  final String message;
  final List<ManagedTrack> tracks;
  final List<ManagedTrack> likedTracks;
  final List<ManagedTrack> repostedTracks;

  ProfileUpdateError(
    this.currentProfile,
    this.message, {
    this.tracks = const <ManagedTrack>[],
    this.likedTracks = const <ManagedTrack>[],
    this.repostedTracks = const <ManagedTrack>[],
  });
}

class ProfileImageUploading extends ProfileState {
  final ProfileEntity currentProfile;
  final ProfileImageType imageType;
  final List<ManagedTrack> tracks;
  final List<ManagedTrack> likedTracks;
  final List<ManagedTrack> repostedTracks;

  ProfileImageUploading(
    this.currentProfile,
    this.imageType, {
    this.tracks = const <ManagedTrack>[],
    this.likedTracks = const <ManagedTrack>[],
    this.repostedTracks = const <ManagedTrack>[],
  });
}

class ProfileImageUploadError extends ProfileState {
  final ProfileEntity currentProfile;
  final ProfileImageType imageType;
  final String filePath;
  final String message;
  final List<ManagedTrack> tracks;
  final List<ManagedTrack> likedTracks;
  final List<ManagedTrack> repostedTracks;

  ProfileImageUploadError(
    this.currentProfile, {
    required this.imageType,
    required this.filePath,
    required this.message,
    this.tracks = const <ManagedTrack>[],
    this.likedTracks = const <ManagedTrack>[],
    this.repostedTracks = const <ManagedTrack>[],
  });
}