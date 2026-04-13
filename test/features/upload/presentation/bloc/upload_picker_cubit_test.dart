import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/errors/upload_picker_exceptions.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/managed_track.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/picked_audio_file.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_management_visibility.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_processing_status.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_status.dart';
import 'package:soundcloud_clone/features/upload/domain/repositories/upload_repository.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/pick_audi_file_usecase.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/update_track_visibility_usecase.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/watch_track_processing_status_use_case.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/upload_picker_cubit.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/upload_picker_state.dart';

class MockPickAudioFileUseCase extends Mock implements PickAudioFileUseCase {}

class MockUploadRepository extends Mock implements UploadRepository {}

class MockWatchTrackProcessingStatusUseCase extends Mock
    implements WatchTrackProcessingStatusUseCase {}

class MockUpdateTrackVisibilityUseCase extends Mock
    implements UpdateTrackVisibilityUseCase {}

void _noopProgress(double _) {}

void main() {
  late MockPickAudioFileUseCase mockPickAudioFileUseCase;
  late MockUploadRepository mockUploadRepository;
  late MockWatchTrackProcessingStatusUseCase
      mockWatchTrackProcessingStatusUseCase;
  late MockUpdateTrackVisibilityUseCase mockUpdateTrackVisibilityUseCase;
  late UploadPickerCubit cubit;

  const tPickedAudioFile = PickedAudioFile(
    name: 'selected_audio.mp3',
    extension: 'mp3',
    sizeInBytes: 4096,
    path: '/storage/emulated/0/Download/selected_audio.mp3',
  );

  const tFinishedUploadTrackResult = UploadTrackResult(
    trackId: 'track-123',
    status: 'FINISHED',
  );

  UploadPickerCubit buildCubit() => UploadPickerCubit(
        mockPickAudioFileUseCase,
        mockUploadRepository,
        mockWatchTrackProcessingStatusUseCase,
        mockUpdateTrackVisibilityUseCase,
      );

  setUpAll(() {
    registerFallbackValue(_noopProgress);
  });

  setUp(() {
    mockPickAudioFileUseCase = MockPickAudioFileUseCase();
    mockUploadRepository = MockUploadRepository();
    mockWatchTrackProcessingStatusUseCase =
        MockWatchTrackProcessingStatusUseCase();
    mockUpdateTrackVisibilityUseCase = MockUpdateTrackVisibilityUseCase();
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
    expect(cubit.state.uploadProgress, isNull);
    expect(cubit.state.uploadedVisibility, isNull);
    expect(cubit.state.privateShareToken, isNull);
  });

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
          description: null,
          tags: const <String>[],
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((_) async => tFinishedUploadTrackResult);

      when(
        () => mockUpdateTrackVisibilityUseCase(
          trackId: 'track-123',
          visibility: TrackManagementVisibility.privateTrack,
        ),
      ).thenAnswer(
        (_) async => const ManagedTrack(
          id: 'track-123',
          title: 'My Track',
          visibility: TrackManagementVisibility.privateTrack,
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
        processingStatus: 'FINISHED',
        uploadedVisibility: TrackManagementVisibility.privateTrack,
      ),
      const UploadPickerState(
        status: UploadPickerStatus.success,
        pickedAudioFile: tPickedAudioFile,
        uploadedTrackId: 'track-123',
        processingStatus: 'FINISHED',
        uploadedVisibility: TrackManagementVisibility.privateTrack,
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
          description: null,
          tags: const <String>[],
          onProgress: any(named: 'onProgress'),
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
          description: null,
          tags: const <String>[],
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer(
        (_) async => const UploadTrackResult(
          trackId: 'track-123',
          status: 'FAILED',
        ),
      );

      when(
        () => mockUpdateTrackVisibilityUseCase(
          trackId: 'track-123',
          visibility: TrackManagementVisibility.privateTrack,
        ),
      ).thenAnswer(
        (_) async => const ManagedTrack(
          id: 'track-123',
          title: 'My Track',
          visibility: TrackManagementVisibility.privateTrack,
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
        uploadedVisibility: TrackManagementVisibility.privateTrack,
      ),
      const UploadPickerState(
        status: UploadPickerStatus.failure,
        pickedAudioFile: tPickedAudioFile,
        uploadedTrackId: 'track-123',
        processingStatus: 'FAILED',
        uploadedVisibility: TrackManagementVisibility.privateTrack,
        errorMessage: 'Track processing failed. Please try again.',
      ),
    ],
  );

  blocTest<UploadPickerCubit, UploadPickerState>(
    'uploadSelectedFile emits success after processing stream finishes',
    build: () {
      when(
        () => mockUploadRepository.uploadTrack(
          file: tPickedAudioFile,
          title: 'My Track',
          genre: null,
          description: null,
          tags: const <String>[],
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer(
        (_) async => const UploadTrackResult(
          trackId: 'track-123',
          status: 'PROCESSING',
        ),
      );

      when(
        () => mockUpdateTrackVisibilityUseCase(
          trackId: 'track-123',
          visibility: TrackManagementVisibility.privateTrack,
        ),
      ).thenAnswer(
        (_) async => const ManagedTrack(
          id: 'track-123',
          title: 'My Track',
          visibility: TrackManagementVisibility.privateTrack,
        ),
      );

      when(() => mockWatchTrackProcessingStatusUseCase('track-123')).thenAnswer(
        (_) => Stream<TrackProcessingStatus>.fromIterable([
          const TrackProcessingStatus(
            trackId: 'track-123',
            status: TrackStatus.PROCESSING,
          ),
          const TrackProcessingStatus(
            trackId: 'track-123',
            status: TrackStatus.FINISHED,
          ),
        ]),
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
        processingStatus: 'PROCESSING',
        uploadedVisibility: TrackManagementVisibility.privateTrack,
      ),
      const UploadPickerState(
        status: UploadPickerStatus.processing,
        pickedAudioFile: tPickedAudioFile,
        uploadedTrackId: 'track-123',
        processingStatus: 'FINISHED',
        uploadedVisibility: TrackManagementVisibility.privateTrack,
      ),
      const UploadPickerState(
        status: UploadPickerStatus.success,
        pickedAudioFile: tPickedAudioFile,
        uploadedTrackId: 'track-123',
        processingStatus: 'FINISHED',
        uploadedVisibility: TrackManagementVisibility.privateTrack,
      ),
    ],
  );

  blocTest<UploadPickerCubit, UploadPickerState>(
    'uploadSelectedFile stores private share token when returned by upload',
    build: () {
      when(
        () => mockUploadRepository.uploadTrack(
          file: tPickedAudioFile,
          title: 'My Track',
          genre: null,
          description: null,
          tags: const <String>[],
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer(
        (_) async => const UploadTrackResult(
          trackId: 'track-123',
          status: 'FINISHED',
          secretToken: 'secret-123',
        ),
      );

      when(
        () => mockUpdateTrackVisibilityUseCase(
          trackId: 'track-123',
          visibility: TrackManagementVisibility.privateTrack,
        ),
      ).thenAnswer(
        (_) async => const ManagedTrack(
          id: 'track-123',
          title: 'My Track',
          visibility: TrackManagementVisibility.privateTrack,
          secretToken: 'secret-123',
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
        processingStatus: 'FINISHED',
        uploadedVisibility: TrackManagementVisibility.privateTrack,
        privateShareToken: 'secret-123',
      ),
      const UploadPickerState(
        status: UploadPickerStatus.success,
        pickedAudioFile: tPickedAudioFile,
        uploadedTrackId: 'track-123',
        processingStatus: 'FINISHED',
        uploadedVisibility: TrackManagementVisibility.privateTrack,
        privateShareToken: 'secret-123',
      ),
    ],
  );

  blocTest<UploadPickerCubit, UploadPickerState>(
    'uploadSelectedFile updates visibility when public is selected',
    build: () {
      when(
        () => mockUploadRepository.uploadTrack(
          file: tPickedAudioFile,
          title: 'My Track',
          genre: null,
          description: null,
          tags: const <String>[],
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((_) async => tFinishedUploadTrackResult);

      when(
        () => mockUpdateTrackVisibilityUseCase(
          trackId: 'track-123',
          visibility: TrackManagementVisibility.publicTrack,
        ),
      ).thenAnswer(
        (_) async => const ManagedTrack(
          id: 'track-123',
          title: 'My Track',
          visibility: TrackManagementVisibility.publicTrack,
        ),
      );

      return buildCubit();
    },
    seed: () => const UploadPickerState(
      status: UploadPickerStatus.ready,
      pickedAudioFile: tPickedAudioFile,
    ),
    act: (cubit) => cubit.uploadSelectedFile(
      title: 'My Track',
      visibility: TrackManagementVisibility.publicTrack,
    ),
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
        uploadedVisibility: TrackManagementVisibility.publicTrack,
      ),
    ],
    verify: (_) {
      verify(
        () => mockUpdateTrackVisibilityUseCase(
          trackId: 'track-123',
          visibility: TrackManagementVisibility.publicTrack,
        ),
      ).called(1);
    },
  );

  blocTest<UploadPickerCubit, UploadPickerState>(
    'uploadSelectedFile emits failure when public visibility update fails',
    build: () {
      when(
        () => mockUploadRepository.uploadTrack(
          file: tPickedAudioFile,
          title: 'My Track',
          genre: null,
          description: null,
          tags: const <String>[],
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((_) async => tFinishedUploadTrackResult);

      when(
        () => mockUpdateTrackVisibilityUseCase(
          trackId: 'track-123',
          visibility: TrackManagementVisibility.publicTrack,
        ),
      ).thenThrow(Exception('Visibility update failed'));

      return buildCubit();
    },
    seed: () => const UploadPickerState(
      status: UploadPickerStatus.ready,
      pickedAudioFile: tPickedAudioFile,
    ),
    act: (cubit) => cubit.uploadSelectedFile(
      title: 'My Track',
      visibility: TrackManagementVisibility.publicTrack,
    ),
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
        status: UploadPickerStatus.failure,
        pickedAudioFile: tPickedAudioFile,
        uploadedTrackId: 'track-123',
        processingStatus: 'FINISHED',
        uploadedVisibility: TrackManagementVisibility.privateTrack,
        errorMessage:
            'Track uploaded successfully, but it is still private because visibility could not be updated. Visibility update failed',
      ),
    ],
  );

  blocTest<UploadPickerCubit, UploadPickerState>(
    'clearSelection resets state to initial',
    build: buildCubit,
    seed: () => const UploadPickerState(
      status: UploadPickerStatus.ready,
      pickedAudioFile: tPickedAudioFile,
      errorMessage: 'old error',
      uploadedTrackId: 'track-123',
      processingStatus: 'FINISHED',
      uploadProgress: 0.5,
      uploadedVisibility: TrackManagementVisibility.privateTrack,
      privateShareToken: 'secret-123',
    ),
    act: (cubit) => cubit.clearSelection(),
    expect: () => [
      const UploadPickerState(status: UploadPickerStatus.initial),
    ],
  );

  blocTest<UploadPickerCubit, UploadPickerState>(
    'pickAudioFile emits [picking, failure] with permanently denied failure type when permission is permanently denied',
    build: () {
      when(() => mockPickAudioFileUseCase()).thenThrow(
        const UploadPickerPermissionPermanentlyDeniedException(
          'Audio file permission is permanently denied. Please enable it from system settings.',
        ),
      );
      return buildCubit();
    },
    act: (cubit) => cubit.pickAudioFile(),
    expect: () => [
      const UploadPickerState(status: UploadPickerStatus.picking),
      const UploadPickerState(
        status: UploadPickerStatus.failure,
        errorMessage:
            'Audio file permission is permanently denied. Please enable it from system settings.',
        failureType: UploadPickerFailureType.permissionPermanentlyDenied,
      ),
    ],
    verify: (_) {
      verify(() => mockPickAudioFileUseCase()).called(1);
    },
  );

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
