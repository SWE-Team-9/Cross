import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/managed_track.dart';
import '../../domain/entities/track_management_form.dart';
import '../../domain/entities/track_management_visibility.dart';
import '../../domain/usecases/delete_track_usecase.dart';
import '../../domain/usecases/update_track_metadata_usecase.dart';
import '../../domain/usecases/update_track_visibility_usecase.dart';
import 'track_management_state.dart';

class TrackManagementCubit extends Cubit<TrackManagementState> {
  TrackManagementCubit(
    this._updateTrackMetadataUseCase,
    this._updateTrackVisibilityUseCase,
    this._deleteTrackUseCase,
  ) : super(const TrackManagementState());

  final UpdateTrackMetadataUseCase _updateTrackMetadataUseCase;
  final UpdateTrackVisibilityUseCase _updateTrackVisibilityUseCase;
  final DeleteTrackUseCase _deleteTrackUseCase;

  void initialize(ManagedTrack track) {
    emit(
      TrackManagementState(
        status: track.isDeleted
            ? TrackManagementStatus.deleted
            : TrackManagementStatus.ready,
        currentTrack: track,
        form: TrackManagementForm.fromTrack(track),
      ),
    );
  }

  void updateTitle(String value) {
    if (!state.hasTrack) {
      return;
    }

    emit(
      state.copyWith(
        status: TrackManagementStatus.ready,
        form: state.form!.copyWith(title: value),
        clearSuccessMessage: true,
        clearErrorMessage: true,
      ),
    );
  }

  void updateDescription(String value) {
    if (!state.hasTrack) {
      return;
    }

    emit(
      state.copyWith(
        status: TrackManagementStatus.ready,
        form: state.form!.copyWith(description: value),
        clearSuccessMessage: true,
        clearErrorMessage: true,
      ),
    );
  }

  void updateGenre(String genreName) {
    if (!state.hasTrack) {
      return;
    }

    emit(
      state.copyWith(
        status: TrackManagementStatus.ready,
        form: state.form!.copyWith(
          genreName: genreName,
          clearGenreId: true,
        ),
        clearSuccessMessage: true,
        clearErrorMessage: true,
      ),
    );
  }

  void updateTagsFromInput(String rawInput) {
    if (!state.hasTrack) {
      return;
    }

    final List<String> parsedTags = rawInput
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    emit(
      state.copyWith(
        status: TrackManagementStatus.ready,
        form: state.form!.copyWith(tags: parsedTags),
        clearSuccessMessage: true,
        clearErrorMessage: true,
      ),
    );
  }

  void updateVisibility(TrackManagementVisibility visibility) {
    if (!state.hasTrack) {
      return;
    }

    emit(
      state.copyWith(
        status: TrackManagementStatus.ready,
        form: state.form!.copyWith(visibility: visibility),
        clearSuccessMessage: true,
        clearErrorMessage: true,
      ),
    );
  }

  Future<void> saveMetadata() async {
    if (!state.hasTrack || state.isBusy || state.isDeleted) {
      return;
    }

    final TrackManagementForm form = state.form!;

    if (!form.isMetadataValid) {
      emit(
        state.copyWith(
          status: TrackManagementStatus.failure,
          errorMessage: _firstMetadataValidationError(form),
          clearSuccessMessage: true,
        ),
      );
      return;
    }

    if (!form.hasMetadataChangesComparedTo(state.currentTrack!)) {
      return;
    }

    emit(
      state.copyWith(
        status: TrackManagementStatus.saving,
        clearSuccessMessage: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final ManagedTrack apiTrack = await _updateTrackMetadataUseCase(
        trackId: state.currentTrack!.id,
        form: form,
      );
      final ManagedTrack updatedTrack = apiTrack.copyWith(
        title: form.normalizedTitle,
        description: form.normalizedDescription,
        clearDescription: form.normalizedDescription == null,
        genreName: form.normalizedGenreName,
        clearGenreName: form.normalizedGenreName == null,
        tags: form.sanitizedTags,
      );

      emit(
        state.copyWith(
          status: TrackManagementStatus.success,
          currentTrack: updatedTrack,
          form: TrackManagementForm.fromTrack(updatedTrack),
          successMessage: 'Track details updated successfully.',
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: TrackManagementStatus.failure,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
          clearSuccessMessage: true,
        ),
      );
    }
  }

  Future<void> saveVisibility() async {
    if (!state.hasTrack || state.isBusy || state.isDeleted) {
      return;
    }

    if (!state.form!.hasVisibilityChangeComparedTo(state.currentTrack!)) {
      return;
    }

    emit(
      state.copyWith(
        status: TrackManagementStatus.saving,
        clearSuccessMessage: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final ManagedTrack updatedTrack = await _updateTrackVisibilityUseCase(
        trackId: state.currentTrack!.id,
        visibility: state.form!.visibility,
      );

      emit(
        state.copyWith(
          status: TrackManagementStatus.success,
          currentTrack: updatedTrack,
          form: TrackManagementForm.fromTrack(updatedTrack),
          successMessage: 'Track visibility updated successfully.',
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: TrackManagementStatus.failure,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
          clearSuccessMessage: true,
        ),
      );
    }
  }

  Future<void> deleteTrack() async {
    if (!state.hasTrack || state.isBusy || state.isDeleted) {
      return;
    }

    emit(
      state.copyWith(
        status: TrackManagementStatus.deleting,
        clearSuccessMessage: true,
        clearErrorMessage: true,
      ),
    );

    try {
      await _deleteTrackUseCase(
        trackId: state.currentTrack!.id,
      );

      emit(
        state.copyWith(
          status: TrackManagementStatus.deleted,
          currentTrack: state.currentTrack!.copyWith(isDeleted: true),
          successMessage: 'Track deleted successfully.',
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: TrackManagementStatus.failure,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
          clearSuccessMessage: true,
        ),
      );
    }
  }

  void resetForm() {
    if (!state.hasTrack || state.isDeleted) {
      return;
    }

    emit(
      state.copyWith(
        status: TrackManagementStatus.ready,
        form: TrackManagementForm.fromTrack(state.currentTrack!),
        clearSuccessMessage: true,
        clearErrorMessage: true,
      ),
    );
  }

  void clearFeedback() {
    emit(
      state.copyWith(
        status: state.isDeleted
            ? TrackManagementStatus.deleted
            : (state.hasTrack
                ? TrackManagementStatus.ready
                : TrackManagementStatus.initial),
        clearSuccessMessage: true,
        clearErrorMessage: true,
      ),
    );
  }

  String _firstMetadataValidationError(TrackManagementForm form) {
    return form.titleValidationError ??
        form.descriptionValidationError ??
        form.genreValidationError ??
        form.tagsValidationError ??
        'Please review the form and try again.';
  }
}
