import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';
import 'package:soundcloud_clone/features/playlists/presentation/widgets/playlist_editor_sheet.dart';

void main() {
  group('PlaylistEditorSheet', () {
    testWidgets('shows validation message when title is empty', (tester) async {
      await tester.pumpWidget(
        _buildSubject(
          sheet: const PlaylistEditorSheet(
            title: 'Create playlist',
            submitLabel: 'Create',
          ),
        ),
      );

      await _openSheet(tester);

      await tester.tap(find.text('Create'));
      await tester.pump();

      expect(find.text('Playlist title is required'), findsOneWidget);
    });

    testWidgets('returns trimmed result when input is valid', (tester) async {
      PlaylistEditorResult? result;

      await tester.pumpWidget(
        _buildSubject(
          onResult: (value) => result = value,
          sheet: const PlaylistEditorSheet(
            title: 'Create playlist',
            submitLabel: 'Create',
          ),
        ),
      );

      await _openSheet(tester);

      await tester.enterText(_titleField(), '  Mix  ');
      await tester.enterText(_descriptionField(), '  Chill tracks  ');

      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.title, 'Mix');
      expect(result!.description, 'Chill tracks');
      expect(result!.visibility, PlaylistVisibility.publicPlaylist);
      expect(result!.genre, isNull);
      expect(result!.coverImagePath, isNull);
    });

    testWidgets('limits title input to 100 characters', (tester) async {
      await tester.pumpWidget(
        _buildSubject(
          sheet: const PlaylistEditorSheet(
            title: 'Create playlist',
            submitLabel: 'Create',
          ),
        ),
      );

      await _openSheet(tester);

      final longTitle = 'a' * 101;
      await tester.enterText(_titleField(), longTitle);
      await tester.pump();

      final titleField = tester.widget<TextField>(_titleField());

      expect(titleField.controller!.text.length, 100);
    });

    testWidgets('limits description input to 500 characters', (tester) async {
      await tester.pumpWidget(
        _buildSubject(
          sheet: const PlaylistEditorSheet(
            title: 'Create playlist',
            submitLabel: 'Create',
          ),
        ),
      );

      await _openSheet(tester);

      final longDescription = 'a' * 501;
      await tester.enterText(_descriptionField(), longDescription);
      await tester.pump();

      final descriptionField = tester.widget<TextField>(_descriptionField());

      expect(descriptionField.controller!.text.length, 500);
    });
  });
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.text('Open sheet'));
  await tester.pumpAndSettle();

  expect(find.text('Create playlist'), findsOneWidget);
}

Finder _titleField() {
  return find.byType(TextField).at(0);
}

Finder _descriptionField() {
  return find.byType(TextField).at(1);
}

Widget _buildSubject({
  required PlaylistEditorSheet sheet,
  ValueChanged<PlaylistEditorResult?>? onResult,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) {
          return ElevatedButton(
            onPressed: () async {
              final result = await showModalBottomSheet<PlaylistEditorResult>(
                context: context,
                isScrollControlled: true,
                builder: (_) => sheet,
              );
              onResult?.call(result);
            },
            child: const Text('Open sheet'),
          );
        },
      ),
    ),
  );
}
