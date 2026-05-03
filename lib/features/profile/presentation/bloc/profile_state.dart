import '../../../upload/domain/entities/managed_track.dart';
import '../../../playlists/domain/entities/playlist_entity.dart';
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
  final List<PlaylistEntity> playlists;
  final List<PlaylistEntity> likedPlaylists;

  ProfileLoaded(
    this.profile, {
    this.tracks = const <ManagedTrack>[],
    this.likedTracks = const <ManagedTrack>[],
    this.repostedTracks = const <ManagedTrack>[],
    this.playlists = const <PlaylistEntity>[],
    this.likedPlaylists = const <PlaylistEntity>[],
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
  final List<PlaylistEntity> playlists;
  final List<PlaylistEntity> likedPlaylists;

  ProfileUpdating(
    this.currentProfile, {
    this.tracks = const <ManagedTrack>[],
    this.likedTracks = const <ManagedTrack>[],
    this.repostedTracks = const <ManagedTrack>[],
    this.playlists = const <PlaylistEntity>[],
    this.likedPlaylists = const <PlaylistEntity>[],
  });
}

class ProfileUpdateSuccess extends ProfileState {
  final ProfileEntity updatedProfile;
  final List<ManagedTrack> tracks;
  final List<ManagedTrack> likedTracks;
  final List<ManagedTrack> repostedTracks;
  final List<PlaylistEntity> playlists;
  final List<PlaylistEntity> likedPlaylists;

  ProfileUpdateSuccess(
    this.updatedProfile, {
    this.tracks = const <ManagedTrack>[],
    this.likedTracks = const <ManagedTrack>[],
    this.repostedTracks = const <ManagedTrack>[],
    this.playlists = const <PlaylistEntity>[],
    this.likedPlaylists = const <PlaylistEntity>[],
  });
}

class ProfileUpdateError extends ProfileState {
  final ProfileEntity currentProfile;
  final String message;
  final List<ManagedTrack> tracks;
  final List<ManagedTrack> likedTracks;
  final List<ManagedTrack> repostedTracks;
  final List<PlaylistEntity> playlists;
  final List<PlaylistEntity> likedPlaylists;

  ProfileUpdateError(
    this.currentProfile,
    this.message, {
    this.tracks = const <ManagedTrack>[],
    this.likedTracks = const <ManagedTrack>[],
    this.repostedTracks = const <ManagedTrack>[],
    this.playlists = const <PlaylistEntity>[],
    this.likedPlaylists = const <PlaylistEntity>[],
  });
}

class ProfileImageUploading extends ProfileState {
  final ProfileEntity currentProfile;
  final ProfileImageType imageType;
  final List<ManagedTrack> tracks;
  final List<ManagedTrack> likedTracks;
  final List<ManagedTrack> repostedTracks;
  final List<PlaylistEntity> playlists;
  final List<PlaylistEntity> likedPlaylists;

  ProfileImageUploading(
    this.currentProfile,
    this.imageType, {
    this.tracks = const <ManagedTrack>[],
    this.likedTracks = const <ManagedTrack>[],
    this.repostedTracks = const <ManagedTrack>[],
    this.playlists = const <PlaylistEntity>[],
    this.likedPlaylists = const <PlaylistEntity>[],
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
  final List<PlaylistEntity> playlists;
  final List<PlaylistEntity> likedPlaylists;

  ProfileImageUploadError(
    this.currentProfile, {
    required this.imageType,
    required this.filePath,
    required this.message,
    this.tracks = const <ManagedTrack>[],
    this.likedTracks = const <ManagedTrack>[],
    this.repostedTracks = const <ManagedTrack>[],
    this.playlists = const <PlaylistEntity>[],
    this.likedPlaylists = const <PlaylistEntity>[],
  });
}
