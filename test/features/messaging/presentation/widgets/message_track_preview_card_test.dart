import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/shared_track_entity.dart';
import 'package:soundcloud_clone/features/messaging/presentation/widgets/message_track_preview_card.dart';

void main() {
  group('MessageTrackPreviewCard', () {
    const track = SharedTrackEntity(
      id: 'track-1',
      title: 'Track One',
      artist: 'Artist One',
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
              child: MessageTrackPreviewCard(
                track: track,
                isMine: isMine,
                onTap: onTap,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders track label, title, artist, and fallback icon',
        (tester) async {
      await pumpCard(tester);

      expect(find.text('Track'), findsOneWidget);
      expect(find.text('Track One'), findsOneWidget);
      expect(find.text('Artist One'), findsOneWidget);
      expect(find.byIcon(Icons.music_note), findsOneWidget);
    });

    testWidgets('calls custom onTap when tapped', (tester) async {
      var tapped = false;

      await pumpCard(
        tester,
        onTap: () => tapped = true,
      );

      await tester.tap(find.byType(MessageTrackPreviewCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('renders when isMine is true', (tester) async {
      await pumpCard(tester, isMine: true);

      expect(find.text('Track One'), findsOneWidget);
    });
  });
}
