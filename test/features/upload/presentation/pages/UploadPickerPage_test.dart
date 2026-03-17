import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/PickedAudioFile.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/uploadPickerCubit.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/uploadPickerState.dart';
import 'package:soundcloud_clone/features/upload/presentation/pages/UploadPickerPage.dart';

class MockUploadPickerCubit extends MockCubit<UploadPickerState>
    implements UploadPickerCubit {}

void main() {
  late MockUploadPickerCubit mockUploadPickerCubit;

  const pickedAudioFile = PickedAudioFile(
    name: 'song.mp3',
    extension: 'mp3',
    sizeInBytes: 2048,
    path: '/storage/emulated/0/Download/song.mp3',
  );

  Widget buildTestableWidget() {
    return MaterialApp(
      home: BlocProvider<UploadPickerCubit>.value(
        value: mockUploadPickerCubit,
        child: const UploadPickerPage(),
      ),
    );
  }

  setUp(() {
    mockUploadPickerCubit = MockUploadPickerCubit();

    when(() => mockUploadPickerCubit.state)
        .thenReturn(const UploadPickerState());

    when(() => mockUploadPickerCubit.pickAudioFile()).thenAnswer((_) async {});

    when(() => mockUploadPickerCubit.clearSelection()).thenAnswer((_) {});
  });

  testWidgets('renders initial state and triggers pickAudioFile on tap',
      (tester) async {
    await tester.pumpWidget(buildTestableWidget());

    expect(find.text('Audio File Picker'), findsOneWidget);
    expect(find.text('Select MP3 / WAV'), findsOneWidget);

    await tester.tap(find.text('Select MP3 / WAV'));
    await tester.pump();

    verify(() => mockUploadPickerCubit.pickAudioFile()).called(1);
  });

  testWidgets('renders selected file and triggers clearSelection on tap',
      (tester) async {
    const successState = UploadPickerState(
      status: UploadPickerStatus.success,
      pickedAudioFile: pickedAudioFile,
    );

    when(() => mockUploadPickerCubit.state).thenReturn(successState);

    await tester.pumpWidget(buildTestableWidget());

    expect(find.text('Name: song.mp3'), findsOneWidget);
    expect(find.text('Extension: MP3'), findsOneWidget);
    expect(find.text('Size: 2.0 KB'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);

    await tester.tap(find.text('Clear'));
    await tester.pump();

    verify(() => mockUploadPickerCubit.clearSelection()).called(1);
  });

  testWidgets('shows snackbar when state changes to failure', (tester) async {
    whenListen(
      mockUploadPickerCubit,
      Stream<UploadPickerState>.fromIterable(const [
        UploadPickerState(
          status: UploadPickerStatus.failure,
          errorMessage: 'Something went wrong',
        ),
      ]),
      initialState: const UploadPickerState(),
    );

    await tester.pumpWidget(buildTestableWidget());
    await tester.pump();

    expect(find.text('Something went wrong'), findsOneWidget);
  });
}
