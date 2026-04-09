import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/picked_audio_file.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/upload_picker_cubit.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/upload_picker_state.dart';
import 'package:soundcloud_clone/features/upload/presentation/pages/upload_picker_page.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';

class MockUploadPickerCubit extends MockCubit<UploadPickerState>
    implements UploadPickerCubit {}

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  late MockUploadPickerCubit mockUploadPickerCubit;
  late MockAuthCubit mockAuthCubit;

  const tUser = User(
    id: '1',
    email: 'test@artist.com',
    handle: 'testartist',
    displayName: 'Test Artist',
    avatarUrl: null,
    accountType: 'ARTIST',
  );

  const tPickedAudioFile = PickedAudioFile(
    name: 'song.mp3',
    extension: 'mp3',
    sizeInBytes: 2048,
    path: '/mock/path/song.mp3',
  );

  setUp(() {
    mockUploadPickerCubit = MockUploadPickerCubit();
    mockAuthCubit = MockAuthCubit();

    // Authenticate the user once for all tests
    whenListen(
      mockAuthCubit,
      Stream.fromIterable([AuthAuthenticated(tUser)]),
      initialState: AuthAuthenticated(tUser),
    );
    when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(tUser));
  });

  Widget buildTestableWidget() {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: mockAuthCubit),
          BlocProvider<UploadPickerCubit>.value(value: mockUploadPickerCubit),
        ],
        child: const Scaffold(body: UploadPickerPage()),
      ),
    );
  }

  group('UploadPickerPage UI Tests', () {
    testWidgets('renders initial state and triggers pickAudioFile on tap',
        (tester) async {
      const initialState = UploadPickerState();
      when(() => mockUploadPickerCubit.state).thenReturn(initialState);
      whenListen(
        mockUploadPickerCubit,
        Stream.value(initialState),
        initialState: initialState,
      );

      when(() => mockUploadPickerCubit.pickAudioFile())
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Upload Track'), findsWidgets);
      expect(find.text('Select MP3 / WAV'), findsOneWidget);

      await tester.tap(find.text('Select MP3 / WAV'));
      await tester.pump();

      verify(() => mockUploadPickerCubit.pickAudioFile()).called(1);
    });

    testWidgets('renders selected file and triggers clearSelection on tap',
        (tester) async {
      // FIX: Increase the test screen size so the ListView doesn't hide bottom elements
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      // Reset screen size after test completes
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const readyState = UploadPickerState(
        status: UploadPickerStatus.ready,
        pickedAudioFile: tPickedAudioFile,
      );

      when(() => mockUploadPickerCubit.state).thenReturn(readyState);
      whenListen(
        mockUploadPickerCubit,
        Stream.value(readyState),
        initialState: readyState,
      );
      when(() => mockUploadPickerCubit.clearSelection()).thenReturn(null);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Because the screen is larger, these will now easily be found in the tree
      expect(find.text('Clear'), findsOneWidget);
      expect(find.text('Ready to upload'), findsOneWidget);

      await tester.tap(find.text('Clear'));
      await tester.pump();

      verify(() => mockUploadPickerCubit.clearSelection()).called(1);
    });

    testWidgets('shows snackbar and error card when state changes to failure',
        (tester) async {
      // FIX: Increase screen size here too just in case
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = StreamController<UploadPickerState>();

      const initialState = UploadPickerState();
      when(() => mockUploadPickerCubit.state).thenReturn(initialState);
      whenListen(
        mockUploadPickerCubit,
        controller.stream,
        initialState: initialState,
      );

      await tester.pumpWidget(buildTestableWidget());

      controller.add(const UploadPickerState(
        status: UploadPickerStatus.failure,
        errorMessage: 'Network Error',
      ));

      await tester.pumpAndSettle();

      expect(find.text('Network Error'), findsNWidgets(2));
      expect(find.text('Upload failed'), findsOneWidget);

      await controller.close();
    });
  });
}
