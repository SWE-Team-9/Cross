import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/PickedAudioFile.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/uploadPickerState.dart';

void main() {
  group('UploadPickerState', () {
    const pickedAudioFile = PickedAudioFile(
      name: 'song.mp3',
      extension: 'mp3',
      sizeInBytes: 4096,
      path: '/storage/emulated/0/Download/song.mp3',
    );

    test('copyWith updates provided fields', () {
      const state = UploadPickerState();

      final result = state.copyWith(
        status: UploadPickerStatus.success,
        pickedAudioFile: pickedAudioFile,
        errorMessage: 'error',
      );

      expect(
        result,
        const UploadPickerState(
          status: UploadPickerStatus.success,
          pickedAudioFile: pickedAudioFile,
          errorMessage: 'error',
        ),
      );
    });

    test('copyWith clears pickedAudioFile when clearPickedAudioFile is true', () {
      const state = UploadPickerState(
        status: UploadPickerStatus.success,
        pickedAudioFile: pickedAudioFile,
      );

      final result = state.copyWith(
        clearPickedAudioFile: true,
      );

      expect(
        result,
        const UploadPickerState(
          status: UploadPickerStatus.success,
        ),
      );
    });

    test('copyWith clears errorMessage when clearErrorMessage is true', () {
      const state = UploadPickerState(
        status: UploadPickerStatus.failure,
        errorMessage: 'old error',
      );

      final result = state.copyWith(
        clearErrorMessage: true,
      );

      expect(
        result,
        const UploadPickerState(
          status: UploadPickerStatus.failure,
        ),
      );
    });
  });
}