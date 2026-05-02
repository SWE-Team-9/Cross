import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/shared_playlist_entity.dart';
import 'package:soundcloud_clone/features/messaging/presentation/widgets/message_playlist_preview_card.dart';

void main() {
  group('MessagePlaylistPreviewCard', () {
    const playlist = SharedPlaylistEntity(
      id: 'playlist-1',
      title: 'Playlist One',
      tracksCount: 12,
      artworkUrl: null,
    );

    Future<void> pumpCard(
      WidgetTester tester, {
      bool isMine = false,
      VoidCallback? onTap,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MessagePlaylistPreviewCard(
                playlist: playlist,
                isMine: isMine,
                onTap: onTap,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets(
        'renders playlist label, title, tracks count, and fallback icon',
        (tester) async {
      await pumpCard(tester);

      expect(find.text('Playlist'), findsOneWidget);
      expect(find.text('Playlist One'), findsOneWidget);
      expect(find.text('12 tracks'), findsOneWidget);
      expect(find.byIcon(Icons.queue_music), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await pumpCard(
        tester,
        onTap: () => tapped = true,
      );

      await tester.tap(find.byType(MessagePlaylistPreviewCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('renders when isMine is true', (tester) async {
      await pumpCard(tester, isMine: true);

      expect(find.text('Playlist One'), findsOneWidget);
    });
  });
}
