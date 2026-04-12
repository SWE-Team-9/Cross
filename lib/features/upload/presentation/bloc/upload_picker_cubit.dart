import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/upload_picker_exceptions.dart';
import '../../domain/entities/track_management_visibility.dart';
import '../../domain/entities/track_status.dart';
import '../../domain/repositories/upload_repository.dart';
import '../../domain/usecases/pick_audi_file_usecase.dart';
import '../../domain/usecases/update_track_visibility_usecase.dart';
import '../../domain/usecases/watch_track_processing_status_use_case.dart';
import 'upload_picker_state.dart';

class UploadPickerCubit extends Cubit<UploadPickerState> {
  UploadPickerCubit(
    this._pickAudioFileUseCase,
    this._uploadRepository,
    this._watchTrackProcessingStatusUseCase,
    this._updateTrackVisibilityUseCase,
  ) : super(const UploadPickerState());

  final PickAudioFileUseCase _pickAudioFileUseCase;
  final UploadRepository _uploadRepository;
  final WatchTrackProcessingStatusUseCase _watchTrackProcessingStatusUseCase;
  final UpdateTrackVisibilityUseCase _updateTrackVisibilityUseCase;

  Future<void> pickAudioFile() async {
    emit(
      state.copyWith(
        status: UploadPickerStatus.picking,
        clearErrorMessage: true,
        clearFailureType: true,
        clearUploadProgress: true,
        clearUploadedVisibility: true,
        clearPrivateShareToken: true,
      ),
    );

    try {
      final pickedAudioFile = await _pickAudioFileUseCase();

      if (pickedAudioFile == null) {
        emit(
          state.copyWith(
            status: UploadPickerStatus.cancelled,
            clearErrorMessage: true,
            clearFailureType: true,
            clearUploadProgress: true,
            clearUploadedVisibility: true,
            clearPrivateShareToken: true,
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
          clearFailureType: true,
          clearUploadProgress: true,
          clearUploadedVisibility: true,
          clearPrivateShareToken: true,
        ),
      );
    } on UploadPickerPermissionPermanentlyDeniedException catch (error) {
      emit(
        state.copyWith(
          status: UploadPickerStatus.failure,
          errorMessage: error.message,
          failureType: UploadPickerFailureType.permissionPermanentlyDenied,
          clearUploadProgress: true,
          clearUploadedVisibility: true,
          clearPrivateShareToken: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: UploadPickerStatus.failure,
          errorMessage: _readableError(error),
          clearFailureType: true,
          clearUploadProgress: true,
          clearUploadedVisibility: true,
          clearPrivateShareToken: true,
        ),
      );
    }
  }

  Future<void> uploadSelectedFile({
    required String title,
    String? genre,
    String? tagsInput,
    String? description,
    TrackManagementVisibility visibility =
        TrackManagementVisibility.privateTrack,
  }) async {
    final pickedAudioFile = state.pickedAudioFile;

    if (pickedAudioFile == null) {
      emit(
        state.copyWith(
          status: UploadPickerStatus.failure,
          errorMessage: 'Please select an audio file first.',
          clearFailureType: true,
          clearUploadProgress: true,
          clearUploadedVisibility: true,
          clearPrivateShareToken: true,
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
          clearFailureType: true,
          clearUploadProgress: true,
          clearUploadedVisibility: true,
          clearPrivateShareToken: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: UploadPickerStatus.uploading,
        clearErrorMessage: true,
        clearFailureType: true,
        clearUploadProgress: true,
        clearUploadedVisibility: true,
        clearPrivateShareToken: true,
      ),
    );

    try {
      final uploadResult = await _uploadRepository.uploadTrack(
        file: pickedAudioFile,
        title: normalizedTitle,
        genre: _normalizeOptional(genre),
        description: _normalizeOptional(description),
        tags: _parseTagsInput(tagsInput),
        onProgress: (progress) {
          emit(
            state.copyWith(
              status: UploadPickerStatus.uploading,
              uploadProgress: progress,
              clearErrorMessage: true,
              clearFailureType: true,
            ),
          );
        },
      );

      final TrackStatus initialStatus = TrackStatus.fromString(
        uploadResult.status,
      );

      String? privateShareToken = uploadResult.secretToken;

      try {
        final updatedTrack = await _updateTrackVisibilityUseCase(
          trackId: uploadResult.trackId,
          visibility: visibility,
        );

        if (visibility == TrackManagementVisibility.privateTrack) {
          privateShareToken = updatedTrack.secretToken ?? privateShareToken;
        } else {
          privateShareToken = null;
        }
      } catch (error) {
        emit(
          state.copyWith(
            status: UploadPickerStatus.failure,
            uploadedTrackId: uploadResult.trackId,
            processingStatus: initialStatus.name,
            errorMessage:
                'Track uploaded, but visibility could not be updated. ${_readableError(error)}',
            clearFailureType: true,
            clearUploadProgress: true,
            clearUploadedVisibility: true,
            clearPrivateShareToken: true,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: UploadPickerStatus.processing,
          uploadedTrackId: uploadResult.trackId,
          processingStatus: initialStatus.name,
          uploadedVisibility: visibility,
          privateShareToken: privateShareToken,
          clearErrorMessage: true,
          clearFailureType: true,
          clearUploadProgress: true,
        ),
      );

      if (initialStatus == TrackStatus.FAILED) {
        emit(
          state.copyWith(
            status: UploadPickerStatus.failure,
            processingStatus: initialStatus.name,
            errorMessage: 'Track processing failed. Please try again.',
            clearFailureType: true,
            clearUploadProgress: true,
          ),
        );
        return;
      }

      if (initialStatus.isReady) {
        emit(
          state.copyWith(
            status: UploadPickerStatus.success,
            processingStatus: initialStatus.name,
            clearErrorMessage: true,
            clearFailureType: true,
            clearUploadProgress: true,
          ),
        );
        return;
      }

      await for (final processingStatus
          in _watchTrackProcessingStatusUseCase(uploadResult.trackId)) {
        final TrackStatus polledStatus = processingStatus.status;

        emit(
          state.copyWith(
            status: UploadPickerStatus.processing,
            uploadedTrackId: uploadResult.trackId,
            processingStatus: polledStatus.name,
            clearErrorMessage: true,
            clearFailureType: true,
            clearUploadProgress: true,
          ),
        );

        if (polledStatus.isReady) {
          emit(
            state.copyWith(
              status: UploadPickerStatus.success,
              processingStatus: polledStatus.name,
              clearErrorMessage: true,
              clearFailureType: true,
              clearUploadProgress: true,
            ),
          );
          return;
        }

        if (polledStatus == TrackStatus.FAILED) {
          emit(
            state.copyWith(
              status: UploadPickerStatus.failure,
              processingStatus: polledStatus.name,
              errorMessage: 'Track processing failed. Please try again.',
              clearFailureType: true,
              clearUploadProgress: true,
            ),
          );
          return;
        }
      }

      emit(
        state.copyWith(
          status: UploadPickerStatus.failure,
          errorMessage:
              'Track is still processing. Please check again in a moment.',
          clearFailureType: true,
          clearUploadProgress: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: UploadPickerStatus.failure,
          errorMessage: _readableError(error),
          clearFailureType: true,
          clearUploadProgress: true,
          clearUploadedVisibility: true,
          clearPrivateShareToken: true,
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
        clearFailureType: true,
        clearUploadProgress: true,
        clearUploadedVisibility: true,
        clearPrivateShareToken: true,
      ),
    );
  }

  List<String> _parseTagsInput(String? rawInput) {
    if (rawInput == null || rawInput.trim().isEmpty) {
      return const <String>[];
    }

    final List<String> result = <String>[];
    final Set<String> seen = <String>{};

    for (final rawTag in rawInput.split(',')) {
      final String trimmed = rawTag.trim();
      final String normalized = trimmed.toLowerCase();

      if (trimmed.isEmpty || seen.contains(normalized)) {
        continue;
      }

      if (result.length >= 10) {
        break;
      }

      result.add(trimmed);
      seen.add(normalized);
    }

    return result;
  }

  String? _normalizeOptional(String? value) {
    final String normalized = (value ?? '').trim();
    return normalized.isEmpty ? null : normalized;
  }

  String _readableError(Object error) {
    final raw = error.toString().trim();
    return raw.replaceFirst('Exception: ', '');
  }
}
