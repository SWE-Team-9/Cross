import 'package:equatable/equatable.dart';

import '../../domain/entities/PickedAudioFile.dart';

enum UploadPickerStatus {
  initial,
  loading,
  success,
  cancelled,
  failure,
}

class UploadPickerState extends Equatable {
  const UploadPickerState({
    this.status = UploadPickerStatus.initial,
    this.pickedAudioFile,
    this.errorMessage,
  });

  final UploadPickerStatus status;
  final PickedAudioFile? pickedAudioFile;
  final String? errorMessage;

  UploadPickerState copyWith({
    UploadPickerStatus? status,
    PickedAudioFile? pickedAudioFile,
    String? errorMessage,
    bool clearPickedAudioFile = false,
    bool clearErrorMessage = false,
  }) {
    return UploadPickerState(
      status: status ?? this.status,
      pickedAudioFile: clearPickedAudioFile
          ? null
          : (pickedAudioFile ?? this.pickedAudioFile),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        pickedAudioFile,
        errorMessage,
      ];
}