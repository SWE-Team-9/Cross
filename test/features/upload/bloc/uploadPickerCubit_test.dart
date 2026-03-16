import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/PickedAudioFile.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/pickAudioFileUseCase.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/uploadPickerCubit.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/uploadPickerState.dart';

class MockPickAudioFileUseCase extends Mock implements PickAudioFileUseCase {}

void main() {
  late MockPickAudioFileUseCase mockPickAudioFileUseCase;
  late UploadPickerCubit cubit;

  const tPickedAudioFile = PickedAudioFile(
    name: 'selected_audio.mp3',
    extension: 'mp3',
    sizeInBytes: 4096,
    path: '/storage/emulated/0/Download/selected_audio.mp3',
  );

  setUp(() {
    mockPickAudioFileUseCase = MockPickAudioFileUseCase();
    cubit = UploadPickerCubit(mockPickAudioFileUseCase);
  });

  tearDown(() async {
    await cubit.close();
  });

  test('initial state should be UploadPickerState()', () {
    expect(cubit.state.status, UploadPickerStatus.initial);
    expect(cubit.state.pickedAudioFile, isNull);
    expect(cubit.state.errorMessage, isNull);
  });

  blocTest<UploadPickerCubit, UploadPickerState>(
    'emits [loading, success] when file is picked successfully',
    build: () {
      when(() => mockPickAudioFileUseCase())
          .thenAnswer((_) async => tPickedAudioFile);
      return UploadPickerCubit(mockPickAudioFileUseCase);
    },
    act: (cubit) => cubit.pickAudioFile(),
    expect: () => [
      const UploadPickerState(
        status: UploadPickerStatus.loading,
      ),
      const UploadPickerState(
        status: UploadPickerStatus.success,
        pickedAudioFile: tPickedAudioFile,
      ),
    ],
    verify: (_) {
      verify(() => mockPickAudioFileUseCase()).called(1);
    },
  );

  blocTest<UploadPickerCubit, UploadPickerState>(
    'emits [loading, cancelled] when user cancels file picking',
    build: () {
      when(() => mockPickAudioFileUseCase()).thenAnswer((_) async => null);
      return UploadPickerCubit(mockPickAudioFileUseCase);
    },
    act: (cubit) => cubit.pickAudioFile(),
    expect: () => [
      const UploadPickerState(
        status: UploadPickerStatus.loading,
      ),
      const UploadPickerState(
        status: UploadPickerStatus.cancelled,
      ),
    ],
    verify: (_) {
      verify(() => mockPickAudioFileUseCase()).called(1);
    },
  );

  blocTest<UploadPickerCubit, UploadPickerState>(
    'emits [loading, failure] when use case throws',
    build: () {
      when(() => mockPickAudioFileUseCase())
          .thenThrow(Exception('Failed to pick audio file'));
      return UploadPickerCubit(mockPickAudioFileUseCase);
    },
    act: (cubit) => cubit.pickAudioFile(),
    expect: () => [
      const UploadPickerState(
        status: UploadPickerStatus.loading,
      ),
      const UploadPickerState(
        status: UploadPickerStatus.failure,
        errorMessage: 'Exception: Failed to pick audio file',
      ),
    ],
    verify: (_) {
      verify(() => mockPickAudioFileUseCase()).called(1);
    },
  );

  blocTest<UploadPickerCubit, UploadPickerState>(
    'clearSelection emits initial state with cleared file and error',
    build: () => UploadPickerCubit(mockPickAudioFileUseCase),
    seed: () => const UploadPickerState(
      status: UploadPickerStatus.success,
      pickedAudioFile: tPickedAudioFile,
      errorMessage: 'old error',
    ),
    act: (cubit) => cubit.clearSelection(),
    expect: () => [
      const UploadPickerState(
        status: UploadPickerStatus.initial,
      ),
    ],
  );
}