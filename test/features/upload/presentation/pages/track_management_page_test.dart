import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/upload/data/repositories/track_management_repository_fake.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/managed_track.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_management_visibility.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/delete_track_usecase.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/update_track_metadata_usecase.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/update_track_visibility_usecase.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/track_management_cubit.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/track_management_state.dart';
import 'package:soundcloud_clone/features/upload/presentation/pages/track_management_page.dart';

void main() {
  const initialTrack = ManagedTrack(
    id: 'demo-track-001',
    title: 'Midnight Echoes',
    description: 'Sprint 2 local demo track for edit/delete testing.',
    genreId: 1,
    genreName: 'Ambient',
    tags: <String>['demo', 'sprint2'],
    visibility: TrackManagementVisibility.publicTrack,
    durationInSeconds: 212,
  );

  TrackManagementCubit buildCubit({
    MockTrackManagementMode mode = MockTrackManagementMode.success,
  }) {
    final repository = TrackManagementRepositoryFake(mode: mode);
    return TrackManagementCubit(
      UpdateTrackMetadataUseCase(repository),
      UpdateTrackVisibilityUseCase(repository),
      DeleteTrackUseCase(repository),
    );
  }

  Future<void> pumpPage(
    WidgetTester tester, {
    required TrackManagementCubit cubit,
    bool popOnSuccess = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<TrackManagementCubit>.value(
          value: cubit,
          child: TrackManagementPage(
            initialTrack: initialTrack,
            popOnSuccess: popOnSuccess,
          ),
        ),
      ),
    );
  }

  Future<void> scrollTo(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.scrollUntilVisible(
      finder,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
  }

  group('TrackManagementPage', () {
    testWidgets('renders page with seeded track', (tester) async {
      final cubit = buildCubit();
      await pumpPage(tester, cubit: cubit);

      await tester.pumpAndSettle();

      expect(find.text('Track Management'), findsOneWidget);
      expect(find.text('Current Track'), findsOneWidget);
      expect(find.text('Visibility'), findsOneWidget);
      expect(find.text('Danger Zone'), findsOneWidget);
      expect(find.text('Delete Track'), findsWidgets);

      await cubit.close();
    });

    testWidgets('shows loading indicator before initialization completes',
        (tester) async {
      final cubit = buildCubit();
      await pumpPage(tester, cubit: cubit);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
      await cubit.close();
    });

    testWidgets('editing title enables save details and persists update',
        (tester) async {
      final cubit = buildCubit();
      await pumpPage(tester, cubit: cubit, popOnSuccess: false);
      await tester.pumpAndSettle();

      final saveDetailsButton =
          find.widgetWithText(FilledButton, 'Save Details');
      FilledButton button = tester.widget(saveDetailsButton);
      expect(button.onPressed, isNull);

      await tester.enterText(
          find.widgetWithText(TextField, 'Title'), 'Updated Track');
      await tester.pump();

      button = tester.widget(saveDetailsButton);
      expect(button.onPressed, isNotNull);

      await scrollTo(tester, saveDetailsButton);
      await tester.tap(saveDetailsButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('Updated Track'), findsWidgets);

      await cubit.close();
    });

    testWidgets('reset restores original metadata after user edits',
        (tester) async {
      final cubit = buildCubit();
      await pumpPage(tester, cubit: cubit, popOnSuccess: false);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Description'),
        'Temporary description',
      );
      await tester.pump();

      final resetButton = find.widgetWithText(OutlinedButton, 'Reset');
      await scrollTo(tester, resetButton);
      await tester.tap(resetButton);
      await tester.pump();

      final TextField descriptionField =
          tester.widget(find.widgetWithText(TextField, 'Description'));
      expect(
        descriptionField.controller?.text,
        'Sprint 2 local demo track for edit/delete testing.',
      );

      await cubit.close();
    });

    testWidgets('changing visibility enables save visibility and persists',
        (tester) async {
      final cubit = buildCubit();
      await pumpPage(tester, cubit: cubit, popOnSuccess: false);
      await tester.pumpAndSettle();

      final saveVisibilityButton =
          find.widgetWithText(FilledButton, 'Save Visibility');
      FilledButton button = tester.widget(saveVisibilityButton);
      expect(button.onPressed, isNull);

      final privateChip = find.widgetWithText(ChoiceChip, 'Private');
      await scrollTo(tester, privateChip);
      await tester.tap(privateChip);
      await tester.pump();

      button = tester.widget(saveVisibilityButton);
      expect(button.onPressed, isNotNull);

      await scrollTo(tester, saveVisibilityButton);
      await tester.tap(saveVisibilityButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.widgetWithText(Chip, 'Private'), findsWidgets);

      await cubit.close();
    });

    testWidgets('more actions button opens actions sheet', (tester) async {
      final cubit = buildCubit();
      await pumpPage(tester, cubit: cubit);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Edit metadata'), findsWidgets);
      expect(find.text('Change visibility'), findsOneWidget);
      expect(find.text('Delete track'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('delete flow can be cancelled from confirmation dialog',
        (tester) async {
      final cubit = buildCubit();
      await pumpPage(tester, cubit: cubit, popOnSuccess: false);
      await tester.pumpAndSettle();

      final deleteTrackButton =
          find.widgetWithText(FilledButton, 'Delete Track');
      await scrollTo(tester, deleteTrackButton);
      await tester.tap(deleteTrackButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('Are you sure you want to delete'),
          findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('This track has been deleted.'), findsNothing);
      expect(find.text('Current Track'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('delete flow shows deleted view when confirmed',
        (tester) async {
      final cubit = buildCubit();
      await pumpPage(tester, cubit: cubit, popOnSuccess: false);
      await tester.pumpAndSettle();

      final deleteTrackButton =
          find.widgetWithText(FilledButton, 'Delete Track');
      await scrollTo(tester, deleteTrackButton);
      await tester.tap(deleteTrackButton);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('This track has been deleted.'), findsOneWidget);
      expect(
        find.text('Close this page to return to your track list.'),
        findsOneWidget,
      );

      await cubit.close();
    });

    testWidgets('shows error snackbar when metadata save fails',
        (tester) async {
      final cubit = buildCubit(mode: MockTrackManagementMode.alwaysFail);
      await pumpPage(tester, cubit: cubit, popOnSuccess: false);
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextField, 'Title'), 'Fail update');
      await tester.pump();

      final saveDetailsButton =
          find.widgetWithText(FilledButton, 'Save Details');
      await scrollTo(tester, saveDetailsButton);
      await tester.tap(saveDetailsButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(cubit.state.status, TrackManagementStatus.ready);
      expect(cubit.state.currentTrack?.title, initialTrack.title);

      await cubit.close();
    });
  });
}
