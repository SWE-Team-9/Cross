// Dart SDK
// Flutter
// Third-party
// Project
import '../../../upload/domain/entities/managed_track.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';

abstract class ProfileState {}

/// Initial state — Cubit just created, no data yet.
class ProfileInitial extends ProfileState {}

/// Loading the profile for the first time — show full-screen spinner.
class ProfileLoading extends ProfileState {}

/// T2.3: Profile loaded — ProfilePage renders all profile data.
class ProfileLoaded extends ProfileState {
  final ProfileEntity profile;
  final List<ManagedTrack> tracks;

  ProfileLoaded(
    this.profile, {
    this.tracks = const <ManagedTrack>[],
  });
}

/// Failed to load the profile.
/// ProfilePage shows error message and a back button.
class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}

/// T2.4: Save in progress — show spinner on the Save button.
/// currentProfile kept so the edit page stays fully rendered.
class ProfileUpdating extends ProfileState {
  final ProfileEntity currentProfile;
  ProfileUpdating(this.currentProfile);
}

/// T2.4: Save succeeded.
/// EditProfilePage listener catches this → shows snackbar → pops.
/// ProfilePage underneath re-renders with updatedProfile automatically.
class ProfileUpdateSuccess extends ProfileState {
  final ProfileEntity updatedProfile;
  ProfileUpdateSuccess(this.updatedProfile);
}

/// T2.4: Save failed.
/// EditProfilePage stays open. Snackbar shows the error message.
/// currentProfile kept so form fields stay populated.
class ProfileUpdateError extends ProfileState {
  final ProfileEntity currentProfile;
  final String message;
  ProfileUpdateError(this.currentProfile, this.message);
}

/// T2.4: Image upload in progress.
/// imageType tells the UI which spinner to show: AVATAR or COVER.
class ProfileImageUploading extends ProfileState {
  final ProfileEntity currentProfile;
  final ProfileImageType imageType;
  ProfileImageUploading(this.currentProfile, this.imageType);
}
