import 'package:equatable/equatable.dart';

import '../../domain/entities/PickedAudioFile.dart';

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

class UploadPickerState extends Equatable {
  const UploadPickerState({
    this.status = UploadPickerStatus.initial,
    this.pickedAudioFile,
    this.errorMessage,
    this.uploadedTrackId,
    this.processingStatus,
  });

  final UploadPickerStatus status;
  final PickedAudioFile? pickedAudioFile;
  final String? errorMessage;
  final String? uploadedTrackId;
  final String? processingStatus;

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
    bool clearPickedAudioFile = false,
    bool clearErrorMessage = false,
    bool clearUploadedTrackId = false,
    bool clearProcessingStatus = false,
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
    );
  }

  @override
  List<Object?> get props => [
        status,
        pickedAudioFile,
        errorMessage,
        uploadedTrackId,
        processingStatus,
      ];
}