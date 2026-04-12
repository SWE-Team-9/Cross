import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/picked_audio_file.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_management_visibility.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/upload_picker_cubit.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/upload_picker_state.dart';
import 'package:soundcloud_clone/features/upload/presentation/pages/upload_picker_page.dart';

class MockUploadPickerCubit extends MockCubit<UploadPickerState>
    implements UploadPickerCubit {}

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  late MockUploadPickerCubit mockUploadPickerCubit;
  late MockAuthCubit mockAuthCubit;

  const artistUser = User(
    id: '1',
    email: 'artist@test.com',
    handle: 'testartist',
    displayName: 'Test Artist',
    avatarUrl: null,
    accountType: 'ARTIST',
  );

  const artistWithoutDisplayName = User(
    id: '2',
    email: 'fallback@test.com',
    handle: 'fallbackartist',
    displayName: '',
    avatarUrl: null,
    accountType: 'ARTIST',
  );

  const listenerUser = User(
    id: '3',
    email: 'listener@test.com',
    handle: 'testlistener',
    displayName: 'Test Listener',
    avatarUrl: null,
    accountType: 'LISTENER',
  );

  const pickedAudioFile = PickedAudioFile(
    name: 'song.mp3',
    extension: 'mp3',
    sizeInBytes: 2048,
    path: '/mock/path/song.mp3',
  );

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: mockAuthCubit),
            BlocProvider<UploadPickerCubit>.value(value: mockUploadPickerCubit),
          ],
          child: const Scaffold(
            body: UploadPickerPage(),
          ),
        ),
      ),
    );
  }

  void stubAuthState(AuthState state) {
    when(() => mockAuthCubit.state).thenReturn(state);
    whenListen(
      mockAuthCubit,
      Stream<AuthState>.fromIterable([state]),
      initialState: state,
    );
  }

  void stubUploadState(UploadPickerState state) {
    when(() => mockUploadPickerCubit.state).thenReturn(state);
    whenListen(
      mockUploadPickerCubit,
      Stream<UploadPickerState>.fromIterable([state]),
      initialState: state,
    );
  }

  Finder textFieldAt(int index) => find.byType(TextField).at(index);

  setUp(() {
    mockUploadPickerCubit = MockUploadPickerCubit();
    mockAuthCubit = MockAuthCubit();
  });

  group('UploadPickerPage', () {
    testWidgets('shows sign in required card when user is not authenticated',
        (tester) async {
      stubAuthState(AuthUnauthenticated());
      stubUploadState(const UploadPickerState());

      await pumpPage(tester);
      await tester.pumpAndSettle();

      expect(find.text('Upload Track'), findsOneWidget);
      expect(find.text('Sign in required'), findsOneWidget);
      expect(
        find.text('Please sign in first to access audio uploads.'),
        findsOneWidget,
      );
      expect(find.text('Select MP3 / WAV'), findsNothing);
    });

    testWidgets(
        'shows artist account required card when authenticated user is not an artist',
        (tester) async {
      stubAuthState(AuthAuthenticated(listenerUser));
      stubUploadState(const UploadPickerState());

      await pumpPage(tester);
      await tester.pumpAndSettle();

      expect(find.text('Artist account required'), findsOneWidget);
      expect(
        find.textContaining('Your current account type is LISTENER'),
        findsOneWidget,
      );
      expect(find.text('Select MP3 / WAV'), findsNothing);
    });

    testWidgets('falls back to email when display name is empty',
        (tester) async {
      stubAuthState(AuthAuthenticated(artistWithoutDisplayName));
      stubUploadState(const UploadPickerState());

      await pumpPage(tester);
      await tester.pumpAndSettle();

      expect(find.text('fallback@test.com'), findsOneWidget);
      expect(find.text('Account type: ARTIST'), findsOneWidget);
      expect(find.text('ARTIST'), findsWidgets);
    });

    testWidgets(
        'renders initial artist state and triggers pickAudioFile on tap',
        (tester) async {
      stubAuthState(AuthAuthenticated(artistUser));
      stubUploadState(const UploadPickerState());
      when(() => mockUploadPickerCubit.pickAudioFile())
          .thenAnswer((_) async {});

      await pumpPage(tester);
      await tester.pumpAndSettle();

      expect(find.text('Select MP3 / WAV'), findsOneWidget);

      await tester.tap(find.text('Select MP3 / WAV'));
      await tester.pump();

      verify(() => mockUploadPickerCubit.pickAudioFile()).called(1);
    });

    testWidgets('shows picking state and disables select button',
        (tester) async {
      stubAuthState(AuthAuthenticated(artistUser));
      stubUploadState(
        const UploadPickerState(status: UploadPickerStatus.picking),
      );

      await pumpPage(tester);
      await tester.pump();

      final ElevatedButton selectButton = tester.widget(
        find.widgetWithText(ElevatedButton, 'Selecting...'),
      );

      expect(selectButton.onPressed, isNull);
      expect(find.text('Selecting file'), findsOneWidget);
      expect(
        find.text('Please choose a supported MP3 or WAV file.'),
        findsOneWidget,
      );
    });

    testWidgets('renders selected file and triggers clearSelection on tap',
        (tester) async {
      stubAuthState(AuthAuthenticated(artistUser));
      stubUploadState(
        const UploadPickerState(
          status: UploadPickerStatus.ready,
          pickedAudioFile: pickedAudioFile,
        ),
      );
      when(() => mockUploadPickerCubit.clearSelection()).thenReturn(null);

      await pumpPage(tester);
      await tester.pumpAndSettle();

      expect(find.text('Clear'), findsOneWidget);
      expect(find.text('Ready to upload'), findsOneWidget);

      await tester.tap(find.text('Clear'));
      await tester.pump();

      verify(() => mockUploadPickerCubit.clearSelection()).called(1);
    });

    testWidgets('clear button clears text controllers before calling cubit',
        (tester) async {
      stubAuthState(AuthAuthenticated(artistUser));
      stubUploadState(
        const UploadPickerState(
          status: UploadPickerStatus.ready,
          pickedAudioFile: pickedAudioFile,
        ),
      );
      when(() => mockUploadPickerCubit.clearSelection()).thenReturn(null);

      await pumpPage(tester);
      await tester.pumpAndSettle();

      await tester.enterText(textFieldAt(0), 'My Track');
      await tester.enterText(textFieldAt(1), 'Pop');
      await tester.enterText(textFieldAt(2), 'lofi, chill');
      await tester.enterText(textFieldAt(3), 'Description');
      await tester.pump();

      await tester.tap(find.text('Clear'));
      await tester.pump();

      verify(() => mockUploadPickerCubit.clearSelection()).called(1);

      final TextField titleField = tester.widget(textFieldAt(0));
      final TextField genreField = tester.widget(textFieldAt(1));
      final TextField tagsField = tester.widget(textFieldAt(2));
      final TextField descriptionField = tester.widget(textFieldAt(3));

      expect(titleField.controller!.text, isEmpty);
      expect(genreField.controller!.text, isEmpty);
      expect(tagsField.controller!.text, isEmpty);
      expect(descriptionField.controller!.text, isEmpty);
    });

    testWidgets('upload button passes full metadata to cubit', (tester) async {
      stubAuthState(AuthAuthenticated(artistUser));
      stubUploadState(
        const UploadPickerState(
          status: UploadPickerStatus.ready,
          pickedAudioFile: pickedAudioFile,
        ),
      );

      when(
        () => mockUploadPickerCubit.uploadSelectedFile(
          title: 'My Track',
          genre: 'Pop',
          tagsInput: 'lofi, chill',
          description: 'Nice description',
          visibility: TrackManagementVisibility.publicTrack,
        ),
      ).thenAnswer((_) async {});

      await pumpPage(tester);
      await tester.pumpAndSettle();

      await tester.enterText(textFieldAt(0), 'My Track');
      await tester.enterText(textFieldAt(1), 'Pop');
      await tester.enterText(textFieldAt(2), 'lofi, chill');
      await tester.enterText(textFieldAt(3), 'Nice description');
      await tester.pump();

      await tester.tap(find.text('Public'));
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Upload Track'));
      await tester.pump();

      verify(
        () => mockUploadPickerCubit.uploadSelectedFile(
          title: 'My Track',
          genre: 'Pop',
          tagsInput: 'lofi, chill',
          description: 'Nice description',
          visibility: TrackManagementVisibility.publicTrack,
        ),
      ).called(1);
    });

    testWidgets('shows uploading state and disables form fields and actions',
        (tester) async {
      stubAuthState(AuthAuthenticated(artistUser));
      stubUploadState(
        const UploadPickerState(
          status: UploadPickerStatus.uploading,
          pickedAudioFile: pickedAudioFile,
          uploadProgress: 0.4,
        ),
      );

      await pumpPage(tester);
      await tester.pump();

      final TextField titleField = tester.widget(textFieldAt(0));
      final TextField genreField = tester.widget(textFieldAt(1));
      final TextField tagsField = tester.widget(textFieldAt(2));
      final TextField descriptionField = tester.widget(textFieldAt(3));

      final OutlinedButton clearButton =
          tester.widget(find.widgetWithText(OutlinedButton, 'Clear'));
      final ElevatedButton uploadButton =
          tester.widget(find.widgetWithText(ElevatedButton, 'Uploading...'));

      expect(titleField.enabled, isFalse);
      expect(genreField.enabled, isFalse);
      expect(tagsField.enabled, isFalse);
      expect(descriptionField.enabled, isFalse);
      expect(clearButton.onPressed, isNull);
      expect(uploadButton.onPressed, isNull);

      expect(find.text('Uploading'), findsOneWidget);
      expect(
        find.text('Your file is being sent to the server.'),
        findsOneWidget,
      );
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('40% uploaded'), findsOneWidget);
    });

    testWidgets('shows processing state with track id and processing status',
        (tester) async {
      stubAuthState(AuthAuthenticated(artistUser));
      stubUploadState(
        const UploadPickerState(
          status: UploadPickerStatus.processing,
          pickedAudioFile: pickedAudioFile,
          uploadedTrackId: 'track-123',
          processingStatus: 'PENDING',
        ),
      );

      await pumpPage(tester);
      await tester.pump();

      expect(find.text('Processing'), findsOneWidget);
      expect(find.textContaining('Track ID: track-123'), findsOneWidget);
      expect(find.textContaining('Status: PENDING'), findsOneWidget);
    });

    testWidgets('shows snackbar and error card when state changes to failure',
        (tester) async {
      stubAuthState(AuthAuthenticated(artistUser));

      final controller = StreamController<UploadPickerState>();
      const initialState = UploadPickerState();

      when(() => mockUploadPickerCubit.state).thenReturn(initialState);
      whenListen(
        mockUploadPickerCubit,
        controller.stream,
        initialState: initialState,
      );

      await pumpPage(tester);

      controller.add(
        const UploadPickerState(
          status: UploadPickerStatus.failure,
          errorMessage: 'Network Error',
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Network Error'), findsNWidgets(2));
      expect(find.text('Upload failed'), findsOneWidget);

      await controller.close();
    });

    testWidgets(
        'shows permission settings dialog when permission is permanently denied',
        (tester) async {
      stubAuthState(AuthAuthenticated(artistUser));

      final controller = StreamController<UploadPickerState>();
      const initialState = UploadPickerState();

      when(() => mockUploadPickerCubit.state).thenReturn(initialState);
      whenListen(
        mockUploadPickerCubit,
        controller.stream,
        initialState: initialState,
      );

      await pumpPage(tester);

      controller.add(
        const UploadPickerState(
          status: UploadPickerStatus.failure,
          errorMessage:
              'Audio file permission is permanently denied. Please enable it from system settings.',
          failureType: UploadPickerFailureType.permissionPermanentlyDenied,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Permission required'), findsOneWidget);
      expect(
        find.text(
          'Audio file access is permanently denied. Please enable it from system settings to continue.',
        ),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Open Settings'), findsOneWidget);
      expect(find.text('Upload failed'), findsOneWidget);

      await controller.close();
    });

    testWidgets('shows success state card and success snackbar',
        (tester) async {
      stubAuthState(AuthAuthenticated(artistUser));

      final controller = StreamController<UploadPickerState>();
      const initialState = UploadPickerState(
        status: UploadPickerStatus.ready,
        pickedAudioFile: pickedAudioFile,
      );

      when(() => mockUploadPickerCubit.state).thenReturn(initialState);
      whenListen(
        mockUploadPickerCubit,
        controller.stream,
        initialState: initialState,
      );

      await pumpPage(tester);

      controller.add(
        const UploadPickerState(
          status: UploadPickerStatus.success,
          pickedAudioFile: pickedAudioFile,
          uploadedTrackId: 'track-123',
          processingStatus: 'FINISHED',
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Upload completed successfully.'), findsOneWidget);
      expect(find.text('Upload complete'), findsOneWidget);
      expect(find.textContaining('Track ID: track-123'), findsOneWidget);
      expect(find.textContaining('Status: FINISHED'), findsOneWidget);

      await controller.close();
    });

    testWidgets('hides upload status card for cancelled state', (tester) async {
      stubAuthState(AuthAuthenticated(artistUser));
      stubUploadState(
        const UploadPickerState(status: UploadPickerStatus.cancelled),
      );

      await pumpPage(tester);
      await tester.pumpAndSettle();

      expect(find.text('Selecting file'), findsNothing);
      expect(find.text('Ready to upload'), findsNothing);
      expect(find.text('Uploading'), findsNothing);
      expect(find.text('Processing'), findsNothing);
      expect(find.text('Upload complete'), findsNothing);
      expect(find.text('Upload failed'), findsNothing);
    });
  });
}
