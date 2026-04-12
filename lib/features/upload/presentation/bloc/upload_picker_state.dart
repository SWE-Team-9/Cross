import 'package:equatable/equatable.dart';

import '../../domain/entities/picked_audio_file.dart';

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
    this.failureType = UploadPickerFailureType.none,
  });

  final UploadPickerStatus status;
  final PickedAudioFile? pickedAudioFile;
  final String? errorMessage;
  final String? uploadedTrackId;
  final String? processingStatus;
  final UploadPickerFailureType failureType;

  bool get isBusy =>
      status == UploadPickerStatus.picking ||
      status == UploadPickerStatus.uploading ||
      status == UploadPickerStatus.processing;

  bool get hasSelection => pickedAudioFile != null;

  UploadPickerState copyWith({
    UploadPickerStatus? status,
    PickedAudioFile? pickedAudioFile,
    String? errorMessage,
    String? uploadedTrackId,
    String? processingStatus,
    UploadPickerFailureType? failureType,
    bool clearPickedAudioFile = false,
    bool clearErrorMessage = false,
    bool clearUploadedTrackId = false,
    bool clearProcessingStatus = false,
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
        failureType,
      ];
}
