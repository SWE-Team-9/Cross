import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/uploadRepository.dart';
import '../../domain/usecases/pickAudioFileUseCase.dart';
import 'uploadPickerState.dart';

class UploadPickerCubit extends Cubit<UploadPickerState> {
  UploadPickerCubit(
    this._pickAudioFileUseCase,
    this._uploadRepository,
  ) : super(const UploadPickerState());

  final PickAudioFileUseCase _pickAudioFileUseCase;
  final UploadRepository _uploadRepository;

  Future<void> pickAudioFile() async {
    emit(
      state.copyWith(
        status: UploadPickerStatus.picking,
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
          status: UploadPickerStatus.ready,
          pickedAudioFile: pickedAudioFile,
          clearErrorMessage: true,
          clearUploadedTrackId: true,
          clearProcessingStatus: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: UploadPickerStatus.failure,
          errorMessage: _readableError(error),
        ),
      );
    }
  }

  Future<void> uploadSelectedFile({
    required String title,
    String? genre,
  }) async {
    final pickedAudioFile = state.pickedAudioFile;

    if (pickedAudioFile == null) {
      emit(
        state.copyWith(
          status: UploadPickerStatus.failure,
          errorMessage: 'Please select an audio file first.',
        ),
      );
      return;
    }

    final String normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      emit(
        state.copyWith(
          status: UploadPickerStatus.failure,
          errorMessage: 'Please enter a track title before uploading.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: UploadPickerStatus.uploading,
        clearErrorMessage: true,
      ),
    );

    try {
      final uploadResult = await _uploadRepository.uploadTrack(
        file: pickedAudioFile,
        title: normalizedTitle,
        genre: genre,
      );

      final String initialStatus = uploadResult.status.trim().toUpperCase();

      emit(
        state.copyWith(
          status: UploadPickerStatus.processing,
          uploadedTrackId: uploadResult.trackId,
          processingStatus: initialStatus,
          clearErrorMessage: true,
        ),
      );

      final String finalStatus = await _pollTrackStatus(
        trackId: uploadResult.trackId,
        initialStatus: initialStatus,
      );

      if (finalStatus == 'FINISHED') {
        emit(
          state.copyWith(
            status: UploadPickerStatus.success,
            processingStatus: finalStatus,
            clearErrorMessage: true,
          ),
        );
        return;
      }

      if (finalStatus == 'FAILED') {
        emit(
          state.copyWith(
            status: UploadPickerStatus.failure,
            processingStatus: finalStatus,
            errorMessage: 'Track processing failed. Please try again.',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: UploadPickerStatus.failure,
          processingStatus: finalStatus,
          errorMessage:
              'Track is still processing. Please check again in a moment.',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: UploadPickerStatus.failure,
          errorMessage: _readableError(error),
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
        clearUploadedTrackId: true,
        clearProcessingStatus: true,
      ),
    );
  }

  Future<String> _pollTrackStatus({
    required String trackId,
    required String initialStatus,
  }) async {
    String latestStatus = initialStatus.trim().toUpperCase();

    if (latestStatus == 'FINISHED' || latestStatus == 'FAILED') {
      return latestStatus;
    }

    for (int attempt = 0; attempt < 15; attempt++) {
      await Future.delayed(const Duration(seconds: 2));

      latestStatus = (await _uploadRepository.getTrackStatus(
        trackId: trackId,
      ))
          .trim()
          .toUpperCase();

      emit(
        state.copyWith(
          status: UploadPickerStatus.processing,
          uploadedTrackId: trackId,
          processingStatus: latestStatus,
          clearErrorMessage: true,
        ),
      );

      if (latestStatus == 'FINISHED' || latestStatus == 'FAILED') {
        return latestStatus;
      }
    }

    return latestStatus;
  }

  String _readableError(Object error) {
    final raw = error.toString().trim();
    return raw.replaceFirst('Exception: ', '');
  }
}
