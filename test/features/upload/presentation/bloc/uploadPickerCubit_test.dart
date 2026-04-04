import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/PickedAudioFile.dart';
import 'package:soundcloud_clone/features/upload/domain/repositories/uploadRepository.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/pickAudioFileUseCase.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/uploadPickerCubit.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/uploadPickerState.dart';

class MockPickAudioFileUseCase extends Mock implements PickAudioFileUseCase {}
class MockUploadRepository extends Mock implements UploadRepository {}

void main() {
  late MockPickAudioFileUseCase mockPickAudioFileUseCase;
  late MockUploadRepository mockUploadRepository;
  late UploadPickerCubit cubit;

  const tPickedAudioFile = PickedAudioFile(
    name: 'selected_audio.mp3',
    extension: 'mp3',
    sizeInBytes: 4096,
    path: '/storage/emulated/0/Download/selected_audio.mp3',
  );

  const tUploadTrackResult = UploadTrackResult(
    trackId: 'track-123',
    status: 'FINISHED',
  );

  UploadPickerCubit buildCubit() =>
      UploadPickerCubit(mockPickAudioFileUseCase, mockUploadRepository);

  setUp(() {
    mockPickAudioFileUseCase = MockPickAudioFileUseCase();
    mockUploadRepository = MockUploadRepository();
    cubit = buildCubit();
  });

  tearDown(() async {
    await cubit.close();
  });

  test('initial state should be UploadPickerState()', () {
    expect(cubit.state.status, UploadPickerStatus.initial);
    expect(cubit.state.pickedAudioFile, isNull);
    expect(cubit.state.errorMessage, isNull);
    expect(cubit.state.uploadedTrackId, isNull);
    expect(cubit.state.processingStatus, isNull);
  });

  // ── pickAudioFile ────────────────────────────────────────────────────────

  blocTest<UploadPickerCubit, UploadPickerState>(
    'pickAudioFile emits [picking, ready] when file is picked successfully',
    build: () {
      when(() => mockPickAudioFileUseCase())
          .thenAnswer((_) async => tPickedAudioFile);
      return buildCubit();
    },
    act: (cubit) => cubit.pickAudioFile(),
    expect: () => [
      const UploadPickerState(status: UploadPickerStatus.picking),
      const UploadPickerState(
        status: UploadPickerStatus.ready,
        pickedAudioFile: tPickedAudioFile,
      ),
    ],
    verify: (_) {
      verify(() => mockPickAudioFileUseCase()).called(1);
    },
  );

  blocTest<UploadPickerCubit, UploadPickerState>(
    'pickAudioFile emits [picking, cancelled] when user cancels',
    build: () {
      when(() => mockPickAudioFileUseCase()).thenAnswer((_) async => null);
      return buildCubit();
    },
    act: (cubit) => cubit.pickAudioFile(),
    expect: () => [
      const UploadPickerState(status: UploadPickerStatus.picking),
      const UploadPickerState(status: UploadPickerStatus.cancelled),
    ],
    verify: (_) {
      verify(() => mockPickAudioFileUseCase()).called(1);
    },
  );

  blocTest<UploadPickerCubit, UploadPickerState>(
    'pickAudioFile emits [picking, failure] when use case throws',
    build: () {
      when(() => mockPickAudioFileUseCase())
          .thenThrow(Exception('Failed to pick audio file'));
      return buildCubit();
    },
    act: (cubit) => cubit.pickAudioFile(),
    expect: () => [
      const UploadPickerState(status: UploadPickerStatus.picking),
      const UploadPickerState(
        status: UploadPickerStatus.failure,
        errorMessage: 'Failed to pick audio file',
      ),
    ],
    verify: (_) {
      verify(() => mockPickAudioFileUseCase()).called(1);
    },
  );

  // ── uploadSelectedFile ───────────────────────────────────────────────────

  blocTest<UploadPickerCubit, UploadPickerState>(
    'uploadSelectedFile emits failure when no file is selected',
    build: buildCubit,
    act: (cubit) => cubit.uploadSelectedFile(title: 'My Track'),
    expect: () => [
      const UploadPickerState(
        status: UploadPickerStatus.failure,
        errorMessage: 'Please select an audio file first.',
      ),
    ],
  );

  blocTest<UploadPickerCubit, UploadPickerState>(
    'uploadSelectedFile emits failure when title is empty',
    build: buildCubit,
    seed: () => const UploadPickerState(
      status: UploadPickerStatus.ready,
      pickedAudioFile: tPickedAudioFile,
    ),
    act: (cubit) => cubit.uploadSelectedFile(title: '   '),
    expect: () => [
      const UploadPickerState(
        status: UploadPickerStatus.failure,
        pickedAudioFile: tPickedAudioFile,
        errorMessage: 'Please enter a track title before uploading.',
      ),
    ],
  );

  blocTest<UploadPickerCubit, UploadPickerState>(
    'uploadSelectedFile emits [uploading, processing, success] when upload and processing succeed immediately',
    build: () {
      when(
        () => mockUploadRepository.uploadTrack(
          file: tPickedAudioFile,
          title: 'My Track',
          genre: null,
        ),
      ).thenAnswer((_) async => tUploadTrackResult);
      return buildCubit();
    },
    seed: () => const UploadPickerState(
      status: UploadPickerStatus.ready,
      pickedAudioFile: tPickedAudioFile,
    ),
    act: (cubit) => cubit.uploadSelectedFile(title: 'My Track'),
    expect: () => [
      const UploadPickerState(
        status: UploadPickerStatus.uploading,
        pickedAudioFile: tPickedAudioFile,
      ),
      const UploadPickerState(
        status: UploadPickerStatus.processing,
        pickedAudioFile: tPickedAudioFile,
        uploadedTrackId: 'track-123',
        processingStatus: 'FINISHED',
      ),
      const UploadPickerState(
        status: UploadPickerStatus.success,
        pickedAudioFile: tPickedAudioFile,
        uploadedTrackId: 'track-123',
        processingStatus: 'FINISHED',
      ),
    ],
  );

  blocTest<UploadPickerCubit, UploadPickerState>(
    'uploadSelectedFile emits failure when upload throws',
    build: () {
      when(
        () => mockUploadRepository.uploadTrack(
          file: tPickedAudioFile,
          title: 'My Track',
          genre: null,
        ),
      ).thenThrow(Exception('Network error'));
      return buildCubit();
    },
    seed: () => const UploadPickerState(
      status: UploadPickerStatus.ready,
      pickedAudioFile: tPickedAudioFile,
    ),
    act: (cubit) => cubit.uploadSelectedFile(title: 'My Track'),
    expect: () => [
      const UploadPickerState(
        status: UploadPickerStatus.uploading,
        pickedAudioFile: tPickedAudioFile,
      ),
      const UploadPickerState(
        status: UploadPickerStatus.failure,
        pickedAudioFile: tPickedAudioFile,
        errorMessage: 'Network error',
      ),
    ],
  );

  blocTest<UploadPickerCubit, UploadPickerState>(
    'uploadSelectedFile emits failure when processing status is FAILED',
    build: () {
      when(
        () => mockUploadRepository.uploadTrack(
          file: tPickedAudioFile,
          title: 'My Track',
          genre: null,
        ),
      ).thenAnswer(
        (_) async => const UploadTrackResult(
          trackId: 'track-123',
          status: 'FAILED',
        ),
      );
      return buildCubit();
    },
    seed: () => const UploadPickerState(
      status: UploadPickerStatus.ready,
      pickedAudioFile: tPickedAudioFile,
    ),
    act: (cubit) => cubit.uploadSelectedFile(title: 'My Track'),
    expect: () => [
      const UploadPickerState(
        status: UploadPickerStatus.uploading,
        pickedAudioFile: tPickedAudioFile,
      ),
      const UploadPickerState(
        status: UploadPickerStatus.processing,
        pickedAudioFile: tPickedAudioFile,
        uploadedTrackId: 'track-123',
        processingStatus: 'FAILED',
      ),
      const UploadPickerState(
        status: UploadPickerStatus.failure,
        pickedAudioFile: tPickedAudioFile,
        uploadedTrackId: 'track-123',
        processingStatus: 'FAILED',
        errorMessage: 'Track processing failed. Please try again.',
      ),
    ],
  );

  blocTest<UploadPickerCubit, UploadPickerState>(
    'uploadSelectedFile polls and emits success after pending then finished',
    build: () {
      when(
        () => mockUploadRepository.uploadTrack(
          file: tPickedAudioFile,
          title: 'My Track',
          genre: null,
        ),
      ).thenAnswer(
        (_) async => const UploadTrackResult(
          trackId: 'track-123',
          status: 'PENDING',
        ),
      );
      var pollCount = 0;
      when(
        () => mockUploadRepository.getTrackStatus(trackId: 'track-123'),
      ).thenAnswer((_) async {
        pollCount++;
        return pollCount >= 2 ? 'FINISHED' : 'PENDING';
      });
      return buildCubit();
    },
    seed: () => const UploadPickerState(
      status: UploadPickerStatus.ready,
      pickedAudioFile: tPickedAudioFile,
    ),
    act: (cubit) => cubit.uploadSelectedFile(title: 'My Track'),
    expect: () => [
      const UploadPickerState(
        status: UploadPickerStatus.uploading,
        pickedAudioFile: tPickedAudioFile,
      ),
      const UploadPickerState(
        status: UploadPickerStatus.processing,
        pickedAudioFile: tPickedAudioFile,
        uploadedTrackId: 'track-123',
        processingStatus: 'PENDING',
      ),
      // Only ONE PENDING state - the duplicate has been removed
      const UploadPickerState(
        status: UploadPickerStatus.processing,
        pickedAudioFile: tPickedAudioFile,
        uploadedTrackId: 'track-123',
        processingStatus: 'FINISHED',
      ),
      const UploadPickerState(
        status: UploadPickerStatus.success,
        pickedAudioFile: tPickedAudioFile,
        uploadedTrackId: 'track-123',
        processingStatus: 'FINISHED',
      ),
    ],
  );

  // ── clearSelection ───────────────────────────────────────────────────────

  blocTest<UploadPickerCubit, UploadPickerState>(
    'clearSelection resets state to initial',
    build: buildCubit,
    seed: () => const UploadPickerState(
      status: UploadPickerStatus.ready,
      pickedAudioFile: tPickedAudioFile,
      errorMessage: 'old error',
      uploadedTrackId: 'track-123',
      processingStatus: 'FINISHED',
    ),
    act: (cubit) => cubit.clearSelection(),
    expect: () => [
      const UploadPickerState(status: UploadPickerStatus.initial),
    ],
  );

  // ── isBusy / hasSelection helpers ────────────────────────────────────────

  test('isBusy is true when status is picking, uploading, or processing', () {
    for (final status in [
      UploadPickerStatus.picking,
      UploadPickerStatus.uploading,
      UploadPickerStatus.processing,
    ]) {
      expect(UploadPickerState(status: status).isBusy, isTrue);
    }
  });

  test('isBusy is false for all other statuses', () {
    for (final status in [
      UploadPickerStatus.initial,
      UploadPickerStatus.ready,
      UploadPickerStatus.success,
      UploadPickerStatus.cancelled,
      UploadPickerStatus.failure,
    ]) {
      expect(UploadPickerState(status: status).isBusy, isFalse);
    }
  });

  test('hasSelection is true when pickedAudioFile is set', () {
    expect(
      const UploadPickerState(pickedAudioFile: tPickedAudioFile).hasSelection,
      isTrue,
    );
  });

  test('hasSelection is false when pickedAudioFile is null', () {
    expect(const UploadPickerState().hasSelection, isFalse);
  });
}