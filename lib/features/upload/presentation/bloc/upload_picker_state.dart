import 'package:equatable/equatable.dart';

import '../../domain/entities/picked_audio_file.dart';
import '../../domain/entities/track_management_visibility.dart';

enum UploadPickerStatus {
  initial,
  picking,
  ready,
  uploading,
  processing,
  success,
  cancelled,
  failure,
}

enum UploadPickerFailureType {
  none,
  permissionPermanentlyDenied,
}

class UploadPickerState extends Equatable {
  const UploadPickerState({
    this.status = UploadPickerStatus.initial,
    this.pickedAudioFile,
    this.errorMessage,
    this.uploadedTrackId,
    this.processingStatus,
    this.uploadProgress,
    this.uploadedVisibility,
    this.privateShareToken,
    this.failureType = UploadPickerFailureType.none,
  });

  final UploadPickerStatus status;
  final PickedAudioFile? pickedAudioFile;
  final String? errorMessage;
  final String? uploadedTrackId;
  final String? processingStatus;
  final double? uploadProgress;
  final TrackManagementVisibility? uploadedVisibility;
  final String? privateShareToken;
  final UploadPickerFailureType failureType;

  bool get isBusy =>
      status == UploadPickerStatus.picking ||
      status == UploadPickerStatus.uploading ||
      status == UploadPickerStatus.processing;

  bool get hasSelection => pickedAudioFile != null;

  bool get hasCreatedTrack => uploadedTrackId != null;

  UploadPickerState copyWith({
    UploadPickerStatus? status,
    PickedAudioFile? pickedAudioFile,
    String? errorMessage,
    String? uploadedTrackId,
    String? processingStatus,
    double? uploadProgress,
    TrackManagementVisibility? uploadedVisibility,
    String? privateShareToken,
    UploadPickerFailureType? failureType,
    bool clearPickedAudioFile = false,
    bool clearErrorMessage = false,
    bool clearUploadedTrackId = false,
    bool clearProcessingStatus = false,
    bool clearUploadProgress = false,
    bool clearUploadedVisibility = false,
    bool clearPrivateShareToken = false,
    bool clearFailureType = false,
  }) {
    return UploadPickerState(
      status: status ?? this.status,
      pickedAudioFile: clearPickedAudioFile
          ? null
          : (pickedAudioFile ?? this.pickedAudioFile),
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      uploadedTrackId: clearUploadedTrackId
          ? null
          : (uploadedTrackId ?? this.uploadedTrackId),
      processingStatus: clearProcessingStatus
          ? null
          : (processingStatus ?? this.processingStatus),
      uploadProgress:
          clearUploadProgress ? null : (uploadProgress ?? this.uploadProgress),
      uploadedVisibility: clearUploadedVisibility
          ? null
          : (uploadedVisibility ?? this.uploadedVisibility),
      privateShareToken: clearPrivateShareToken
          ? null
          : (privateShareToken ?? this.privateShareToken),
      failureType: clearFailureType
          ? UploadPickerFailureType.none
          : (failureType ?? this.failureType),
    );
  }

  @override
  List<Object?> get props => [
        status,
        pickedAudioFile,
        errorMessage,
        uploadedTrackId,
        processingStatus,
        uploadProgress,
        uploadedVisibility,
        privateShareToken,
        failureType,
      ];
}
