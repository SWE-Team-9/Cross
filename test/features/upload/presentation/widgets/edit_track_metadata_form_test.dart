import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/managed_track.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_management_form.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_management_visibility.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/track_management_state.dart';
import 'package:soundcloud_clone/features/upload/presentation/widgets/edit_track_metadata_form.dart';

void main() {
  group('EditTrackMetadataForm', () {
    testWidgets('renders fields and triggers save/reset callbacks',
        (tester) async {
      int saveCount = 0;
      int resetCount = 0;

      final state = TrackManagementState(
        status: TrackManagementStatus.ready,
        currentTrack: const ManagedTrack(
          id: 'track-1',
          title: 'Old Title',
          description: 'Old Description',
          genreId: 1,
          genreName: 'Ambient',
          tags: <String>['demo'],
          visibility: TrackManagementVisibility.publicTrack,
        ),
        form: const TrackManagementForm(
          title: 'New Title',
          description: 'New Description',
          genreId: 1,
          genreName: 'Ambient',
          tags: <String>['demo'],
          visibility: TrackManagementVisibility.publicTrack,
        ),
      );

      final titleController = TextEditingController(text: 'New Title');
      final descriptionController =
          TextEditingController(text: 'New Description');
      final tagsController = TextEditingController(text: 'demo');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditTrackMetadataForm(
              state: state,
              titleController: titleController,
              descriptionController: descriptionController,
              tagsController: tagsController,
              genreOptions: const [
                TrackGenreOption(name: 'Ambient'),
                TrackGenreOption(name: 'Electronic'),
              ],
              onTitleChanged: (_) {},
              onDescriptionChanged: (_) {},
              onTagsChanged: (_) {},
              onReleaseDateChanged: (_) {},
              onGenreChanged: (_) {},
              onSave: () => saveCount++,
              onReset: () => resetCount++,
            ),
          ),
        ),
      );

      expect(find.text('Edit metadata'), findsOneWidget);
      expect(find.text('Save Details'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);

      await tester.tap(find.text('Save Details'));
      await tester.pump();

      await tester.tap(find.text('Reset'));
      await tester.pump();

      expect(saveCount, 1);
      expect(resetCount, 1);

      titleController.dispose();
      descriptionController.dispose();
      tagsController.dispose();
    });
  });
}
