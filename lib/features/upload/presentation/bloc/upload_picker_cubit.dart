import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/subscription.dart';
import 'package:soundcloud_clone/features/premium/domain/repositories/subscription_repository.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/check_upload_limit_usecase.dart';

import '../../../../core/errors/upload_picker_exceptions.dart';
import '../../domain/entities/managed_track.dart';
import '../../domain/entities/picked_image_file.dart';
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
    this._subscriptionRepository,
    this._checkUploadLimitUseCase,
  ) : super(const UploadPickerState());

  final PickAudioFileUseCase _pickAudioFileUseCase;
  final UploadRepository _uploadRepository;
  final WatchTrackProcessingStatusUseCase _watchTrackProcessingStatusUseCase;
  final UpdateTrackVisibilityUseCase _updateTrackVisibilityUseCase;
  final SubscriptionRepository _subscriptionRepository;
  final CheckUploadLimitUseCase _checkUploadLimitUseCase;

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
    PickedImageFile? coverArt,
    String? genre,
    String? tagsInput,
    String? description,
    DateTime? releaseDate,
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

    final List<String> parsedTags = _parseTagsInput(tagsInput);
    final String? normalizedDescription = _normalizeOptional(description);
    final String? metadataValidationError = _uploadMetadataValidationError(
      title: normalizedTitle,
      description: normalizedDescription,
      tags: parsedTags,
    );

    if (metadataValidationError != null) {
      emit(
        state.copyWith(
          status: UploadPickerStatus.failure,
          errorMessage: metadataValidationError,
          clearFailureType: true,
          clearUploadProgress: true,
          clearUploadedVisibility: true,
          clearPrivateShareToken: true,
        ),
      );
      return;
    }

    late final Subscription subscription;

    try {
      subscription = await _subscriptionRepository.getMySubscription();
    } catch (_) {
      emit(
        state.copyWith(
          status: UploadPickerStatus.failure,
          errorMessage: 'Failed to check subscription. Please try again.',
          clearFailureType: true,
          clearUploadProgress: true,
          clearUploadedVisibility: true,
          clearPrivateShareToken: true,
        ),
      );
      return;
    }

    final canUpload = _checkUploadLimitUseCase.canUploadSubscription(
      subscription,
    );

    if (!canUpload) {
      emit(
        state.copyWith(
          status: UploadPickerStatus.failure,
          errorMessage: _checkUploadLimitUseCase.limitReachedMessage(
            subscription,
          ),
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
        coverArt: coverArt,
        genre: _normalizeOptional(genre),
        description: normalizedDescription,
        releaseDate: releaseDate,
        tags: parsedTags,
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

      TrackManagementVisibility? uploadedVisibility =
          visibility == TrackManagementVisibility.privateTrack
              ? TrackManagementVisibility.privateTrack
              : null;

      String? privateShareToken =
          visibility == TrackManagementVisibility.privateTrack
              ? uploadResult.secretToken
              : null;

      emit(
        state.copyWith(
          status: UploadPickerStatus.processing,
          uploadedTrackId: uploadResult.trackId,
          processingStatus: initialStatus.name,
          uploadedVisibility: uploadedVisibility,
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
            uploadedTrackId: uploadResult.trackId,
            processingStatus: initialStatus.name,
            uploadedVisibility: uploadedVisibility,
            privateShareToken: privateShareToken,
            errorMessage: 'Track processing failed. Please try again.',
            clearFailureType: true,
            clearUploadProgress: true,
          ),
        );
        return;
      }

      if (initialStatus.isReady) {
        final resolution = await _resolveRequestedVisibility(
          trackId: uploadResult.trackId,
          requestedVisibility: visibility,
          fallbackPrivateShareToken: uploadResult.secretToken,
        );

        uploadedVisibility = resolution.uploadedVisibility;
        privateShareToken = resolution.privateShareToken;

        if (resolution.errorMessage != null) {
          emit(
            state.copyWith(
              status: UploadPickerStatus.failure,
              uploadedTrackId: uploadResult.trackId,
              processingStatus: initialStatus.name,
              uploadedVisibility: uploadedVisibility,
              privateShareToken: privateShareToken,
              errorMessage: resolution.errorMessage,
              clearFailureType: true,
              clearUploadProgress: true,
            ),
          );
          return;
        }

        emit(
          state.copyWith(
            status: UploadPickerStatus.success,
            uploadedTrackId: uploadResult.trackId,
            processingStatus: initialStatus.name,
            uploadedVisibility: uploadedVisibility,
            privateShareToken: privateShareToken,
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
            uploadedVisibility: uploadedVisibility,
            privateShareToken: privateShareToken,
            clearErrorMessage: true,
            clearFailureType: true,
            clearUploadProgress: true,
          ),
        );

        if (polledStatus == TrackStatus.FAILED) {
          emit(
            state.copyWith(
              status: UploadPickerStatus.failure,
              uploadedTrackId: uploadResult.trackId,
              processingStatus: polledStatus.name,
              uploadedVisibility: uploadedVisibility,
              privateShareToken: privateShareToken,
              errorMessage: 'Track processing failed. Please try again.',
              clearFailureType: true,
              clearUploadProgress: true,
            ),
          );
          return;
        }

        if (polledStatus.isReady) {
          final resolution = await _resolveRequestedVisibility(
            trackId: uploadResult.trackId,
            requestedVisibility: visibility,
            fallbackPrivateShareToken: uploadResult.secretToken,
          );

          uploadedVisibility = resolution.uploadedVisibility;
          privateShareToken = resolution.privateShareToken;

          if (resolution.errorMessage != null) {
            emit(
              state.copyWith(
                status: UploadPickerStatus.failure,
                uploadedTrackId: uploadResult.trackId,
                processingStatus: polledStatus.name,
                uploadedVisibility: uploadedVisibility,
                privateShareToken: privateShareToken,
                errorMessage: resolution.errorMessage,
                clearFailureType: true,
                clearUploadProgress: true,
              ),
            );
            return;
          }

          emit(
            state.copyWith(
              status: UploadPickerStatus.success,
              uploadedTrackId: uploadResult.trackId,
              processingStatus: polledStatus.name,
              uploadedVisibility: uploadedVisibility,
              privateShareToken: privateShareToken,
              clearErrorMessage: true,
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
          uploadedTrackId: uploadResult.trackId,
          processingStatus: initialStatus.name,
          uploadedVisibility: uploadedVisibility,
          privateShareToken: privateShareToken,
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

  Future<_VisibilityResolution> _resolveRequestedVisibility({
    required String trackId,
    required TrackManagementVisibility requestedVisibility,
    required String? fallbackPrivateShareToken,
  }) async {
    if (requestedVisibility == TrackManagementVisibility.privateTrack) {
      return _VisibilityResolution(
        uploadedVisibility: TrackManagementVisibility.privateTrack,
        privateShareToken: fallbackPrivateShareToken,
      );
    }

    Object? lastError;

    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final ManagedTrack updatedTrack = await _updateTrackVisibilityUseCase(
          trackId: trackId,
          visibility: TrackManagementVisibility.publicTrack,
        );

        return _VisibilityResolution(
          uploadedVisibility: updatedTrack.visibility,
          privateShareToken:
              updatedTrack.visibility == TrackManagementVisibility.privateTrack
                  ? updatedTrack.secretToken ?? fallbackPrivateShareToken
                  : null,
        );
      } catch (error) {
        lastError = error;

        if (attempt < 2) {
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      }
    }

    return _VisibilityResolution(
      uploadedVisibility: TrackManagementVisibility.privateTrack,
      privateShareToken: fallbackPrivateShareToken,
      errorMessage:
          'Track uploaded successfully, but it is still private because visibility could not be updated. ${_readableError(lastError ?? Exception('Unknown error'))}',
    );
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

  String? _uploadMetadataValidationError({
    required String title,
    required String? description,
    required List<String> tags,
  }) {
    if (title.length > 100) {
      return 'Title must be 100 characters or fewer.';
    }

    if (description != null && description.length > 5000) {
      return 'Description must be 5000 characters or fewer.';
    }

    for (final tag in tags) {
      if (tag.length > 30) {
        return 'Each tag must be 30 characters or fewer.';
      }
    }

    return null;
  }

  String _readableError(Object error) {
    final raw = error.toString().trim();
    return raw.replaceFirst('Exception: ', '');
  }
}

class _VisibilityResolution {
  const _VisibilityResolution({
    required this.uploadedVisibility,
    required this.privateShareToken,
    this.errorMessage,
  });

  final TrackManagementVisibility? uploadedVisibility;
  final String? privateShareToken;
  final String? errorMessage;
}