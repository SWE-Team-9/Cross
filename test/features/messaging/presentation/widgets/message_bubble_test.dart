import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_type.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/shared_playlist_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/shared_track_entity.dart';
import 'package:soundcloud_clone/features/messaging/presentation/widgets/message_bubble.dart';
import 'package:soundcloud_clone/features/messaging/presentation/widgets/message_playlist_preview_card.dart';
import 'package:soundcloud_clone/features/messaging/presentation/widgets/message_track_preview_card.dart';

void main() {
  group('MessageBubble', () {
    MessageEntity message({
      String id = 'message-1',
      MessageType type = MessageType.text,
      String? text = 'Hello',
      SharedTrackEntity? sharedTrack,
      SharedPlaylistEntity? sharedPlaylist,
      DateTime? createdAt,
    }) {
      return MessageEntity(
        id: id,
        conversationId: 'conversation-1',
        senderId: 'sender-1',
        receiverId: 'receiver-1',
        type: type,
        text: text,
        isRead: false,
        createdAt: createdAt ?? DateTime(2026, 4, 30, 13, 5),
        sharedTrack: sharedTrack,
        sharedPlaylist: sharedPlaylist,
      );
    }

    Future<void> pumpBubble(
      WidgetTester tester, {
      required MessageEntity message,
      required bool isMine,
      VoidCallback? onDelete,
      VoidCallback? onTrackTap,
      VoidCallback? onPlaylistTap,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MessageBubble(
                message: message,
                isMine: isMine,
                onDelete: onDelete,
                onTrackTap: onTrackTap,
                onPlaylistTap: onPlaylistTap,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders text and formatted time', (tester) async {
      await pumpBubble(
        tester,
        message: message(),
        isMine: false,
      );

      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('1:05 PM'), findsOneWidget);
    });

    testWidgets('trims text before rendering', (tester) async {
      await pumpBubble(
        tester,
        message: message(text: '  Trim me  '),
        isMine: false,
      );

      expect(find.text('Trim me'), findsOneWidget);
      expect(find.text('  Trim me  '), findsNothing);
    });

    testWidgets('does not render blank text', (tester) async {
      await pumpBubble(
        tester,
        message: message(text: '   '),
        isMine: false,
      );

      expect(find.text('   '), findsNothing);
      expect(find.text('1:05 PM'), findsOneWidget);
    });

    testWidgets('renders track preview for track share message',
        (tester) async {
      const track = SharedTrackEntity(
        id: 'track-1',
        title: 'Track One',
        artist: 'Artist One',
        artworkUrl: null,
      );

      var tapped = false;

      await pumpBubble(
        tester,
        message: message(
          type: MessageType.trackShare,
          text: null,
          sharedTrack: track,
        ),
        isMine: false,
        onTrackTap: () => tapped = true,
      );

      expect(find.byType(MessageTrackPreviewCard), findsOneWidget);
      expect(find.text('Track One'), findsOneWidget);

      await tester.tap(find.byType(MessageTrackPreviewCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('renders playlist preview for playlist share message',
        (tester) async {
      const playlist = SharedPlaylistEntity(
        id: 'playlist-1',
        title: 'Playlist One',
        tracksCount: 8,
        artworkUrl: null,
      );

      var tapped = false;

      await pumpBubble(
        tester,
        message: message(
          type: MessageType.playlistShare,
          text: null,
          sharedPlaylist: playlist,
        ),
        isMine: false,
        onPlaylistTap: () => tapped = true,
      );

      expect(find.byType(MessagePlaylistPreviewCard), findsOneWidget);
      expect(find.text('Playlist One'), findsOneWidget);

      await tester.tap(find.byType(MessagePlaylistPreviewCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('long pressing own text opens delete sheet and deletes',
        (tester) async {
      var deleted = false;

      await pumpBubble(
        tester,
        message: message(),
        isMine: true,
        onDelete: () => deleted = true,
      );

      await tester.longPress(find.text('Hello'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Delete'), findsOneWidget);

      await tester.tap(find.textContaining('Delete'));
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
    });

    testWidgets('long pressing other user message does not open delete sheet',
        (tester) async {
      await pumpBubble(
        tester,
        message: message(),
        isMine: false,
        onDelete: () {},
      );

      await tester.longPress(find.text('Hello'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Delete'), findsNothing);
    });
  });
}
