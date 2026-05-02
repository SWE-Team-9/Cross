import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/playback/presentation/widgets/add_to_playlist_sheet.dart';

void main() {
  Widget buildHost({
    required Track track,
    required String buttonLabel,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: ElevatedButton(
                onPressed: () => AddToPlaylistSheet.show(context, track: track),
                child: Text(buttonLabel),
              ),
            );
          },
        ),
      ),
    );
  }

  group('AddToPlaylistSheet', () {
    testWidgets('renders default playlists', (tester) async {
      const track = Track(
        id: 'coverage-track-1',
        title: 'Song 1',
        artist: 'Ali',
        audioUrl: 'https://example.com/audio.mp3',
      );

      await tester.pumpWidget(
        buildHost(track: track, buttonLabel: 'open sheet'),
      );

      await tester.tap(find.text('open sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Add to playlist'), findsOneWidget);
      expect(find.text('My Favourites'), findsOneWidget);
      expect(find.text('Chill Vibes'), findsOneWidget);
      expect(find.text('Workout Mix'), findsOneWidget);
    });

    testWidgets('adds track to existing playlist and shows snackbar',
        (tester) async {
      const track = Track(
        id: 'coverage-track-2',
        title: 'Song 2',
        artist: 'Ali',
        audioUrl: 'https://example.com/audio.mp3',
      );

      await tester.pumpWidget(
        buildHost(track: track, buttonLabel: 'open existing'),
      );

      await tester.tap(find.text('open existing'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('My Favourites'));
      await tester.pumpAndSettle();

      expect(find.text('Added to My Favourites'), findsOneWidget);

      await tester.tap(find.text('open existing'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check), findsWidgets);
    });

    testWidgets('creates a new playlist and adds the track', (tester) async {
      const track = Track(
        id: 'coverage-track-3',
        title: 'Song 3',
        artist: 'Ali',
        audioUrl: 'https://example.com/audio.mp3',
      );

      await tester.pumpWidget(
        buildHost(track: track, buttonLabel: 'open create'),
      );

      await tester.tap(find.text('open create'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New playlist'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Coverage Playlist');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('Created "Coverage Playlist" and added track'),
          findsOneWidget);

      await tester.tap(find.text('open create'));
      await tester.pumpAndSettle();
      expect(find.text('Coverage Playlist'), findsOneWidget);
    });
  });
}
