import 'package:equatable/equatable.dart';

import '../../domain/entities/managed_track.dart';
import '../../domain/entities/track_management_form.dart';

enum TrackManagementStatus {
  initial,
  ready,
  saving,
  success,
  failure,
  deleting,
  deleted,
}

class TrackManagementState extends Equatable {
  const TrackManagementState({
    this.status = TrackManagementStatus.initial,
    this.currentTrack,
    this.form,
    this.successMessage,
    this.errorMessage,
  });

  final TrackManagementStatus status;
  final ManagedTrack? currentTrack;
  final TrackManagementForm? form;
  final String? successMessage;
  final String? errorMessage;

  bool get hasTrack => currentTrack != null && form != null;

  bool get isBusy =>
      status == TrackManagementStatus.saving ||
      status == TrackManagementStatus.deleting;

  bool get isDeleted =>
      status == TrackManagementStatus.deleted ||
      currentTrack?.isDeleted == true;

  bool get canSaveMetadata =>
      hasTrack &&
      !isBusy &&
      !isDeleted &&
      form!.isMetadataValid &&
      form!.hasMetadataChangesComparedTo(currentTrack!);

  bool get canSaveVisibility =>
      hasTrack &&
      !isBusy &&
      !isDeleted &&
      form!.hasVisibilityChangeComparedTo(currentTrack!);

  TrackManagementState copyWith({
    TrackManagementStatus? status,
    ManagedTrack? currentTrack,
    TrackManagementForm? form,
    String? successMessage,
    String? errorMessage,
    bool clearCurrentTrack = false,
    bool clearForm = false,
    bool clearSuccessMessage = false,
    bool clearErrorMessage = false,
  }) {
    return TrackManagementState(
      status: status ?? this.status,
      currentTrack:
          clearCurrentTrack ? null : (currentTrack ?? this.currentTrack),
      form: clearForm ? null : (form ?? this.form),
      successMessage:
          clearSuccessMessage ? null : (successMessage ?? this.successMessage),
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        currentTrack,
        form,
        successMessage,
        errorMessage,
      ];
}
