import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/pickAudioFileUseCase.dart';
import 'uploadPickerState.dart';

class UploadPickerCubit extends Cubit<UploadPickerState> {
  UploadPickerCubit(this._pickAudioFileUseCase)
      : super(const UploadPickerState());

  final PickAudioFileUseCase _pickAudioFileUseCase;

  Future<void> pickAudioFile() async {
    emit(
      state.copyWith(
        status: UploadPickerStatus.loading,
        clearErrorMessage: true,
      ),
    );

    try {
      final pickedAudioFile = await _pickAudioFileUseCase();

      if (pickedAudioFile == null) {
        emit(
          state.copyWith(
            status: UploadPickerStatus.cancelled,
            clearErrorMessage: true,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: UploadPickerStatus.success,
          pickedAudioFile: pickedAudioFile,
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: UploadPickerStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void clearSelection() {
    emit(
      state.copyWith(
        status: UploadPickerStatus.initial,
        clearPickedAudioFile: true,
        clearErrorMessage: true,
      ),
    );
  }
}
