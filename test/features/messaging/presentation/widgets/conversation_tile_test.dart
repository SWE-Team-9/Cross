import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_type.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/participant_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/shared_playlist_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/shared_track_entity.dart';
import 'package:soundcloud_clone/features/messaging/presentation/widgets/conversation_tile.dart';
import 'package:soundcloud_clone/features/messaging/presentation/widgets/unread_badge.dart';

void main() {
  group('ConversationTile', () {
    const participant = ParticipantEntity(
      id: 'user-1',
      displayName: 'Listener One',
      handle: 'listener',
      avatarUrl: null,
    );

    MessageEntity message({
      MessageType type = MessageType.text,
      String? text = 'Hello',
      SharedTrackEntity? sharedTrack,
      SharedPlaylistEntity? sharedPlaylist,
    }) {
      return MessageEntity(
        id: 'message-1',
        conversationId: 'conversation-1',
        senderId: 'sender-1',
        receiverId: 'receiver-1',
        type: type,
        text: text,
        isRead: false,
        createdAt: DateTime(2026, 4, 30, 9, 7),
        sharedTrack: sharedTrack,
        sharedPlaylist: sharedPlaylist,
      );
    }

    ConversationEntity conversation({
      MessageEntity? lastMessage,
      int unreadCount = 0,
      ParticipantEntity customParticipant = participant,
    }) {
      return ConversationEntity(
        conversationId: 'conversation-1',
        participant: customParticipant,
        lastMessage: lastMessage,
        unreadCount: unreadCount,
      );
    }

    Future<void> pumpTile(
      WidgetTester tester, {
      required ConversationEntity conversation,
      VoidCallback? onTap,
      VoidCallback? onMorePressed,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConversationTile(
              conversation: conversation,
              onTap: onTap ?? () {},
              onMorePressed: onMorePressed,
            ),
          ),
        ),
      );
    }

    testWidgets('renders participant name, handle, and no messages fallback',
        (tester) async {
      await pumpTile(
        tester,
        conversation: conversation(),
      );

      expect(find.text('Listener One'), findsOneWidget);
      expect(find.text('@listener'), findsOneWidget);
      expect(find.text('No messages yet'), findsOneWidget);
      expect(find.byType(UnreadBadge), findsOneWidget);
    });

    testWidgets('renders text last message and formatted time', (tester) async {
      await pumpTile(
        tester,
        conversation: conversation(
          lastMessage: message(text: '  Hello world  '),
          unreadCount: 3,
        ),
      );

      expect(find.text('Hello world'), findsOneWidget);
      expect(find.text('9:07 AM'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('renders text fallback for blank text message', (tester) async {
      await pumpTile(
        tester,
        conversation: conversation(
          lastMessage: message(text: '   '),
        ),
      );

      expect(find.text('Text message'), findsOneWidget);
    });

    testWidgets('renders track share last message', (tester) async {
      await pumpTile(
        tester,
        conversation: conversation(
          lastMessage: message(
            type: MessageType.trackShare,
            text: null,
            sharedTrack: const SharedTrackEntity(
              id: 'track-1',
              title: 'Track One',
              artist: 'Artist One',
              artworkUrl: null,
            ),
          ),
        ),
      );

      expect(find.text('🎵 Track One'), findsOneWidget);
    });

    testWidgets('renders playlist share last message', (tester) async {
      await pumpTile(
        tester,
        conversation: conversation(
          lastMessage: message(
            type: MessageType.playlistShare,
            text: null,
            sharedPlaylist: const SharedPlaylistEntity(
              id: 'playlist-1',
              title: 'Playlist One',
              tracksCount: 8,
              artworkUrl: null,
            ),
          ),
        ),
      );

      expect(find.text('📚 Playlist One'), findsOneWidget);
    });

    testWidgets('renders unsupported message fallback', (tester) async {
      await pumpTile(
        tester,
        conversation: conversation(
          lastMessage: message(
            type: MessageType.unknown,
            text: null,
          ),
        ),
      );

      expect(find.text('Unsupported message'), findsOneWidget);
    });

    testWidgets('uses question mark avatar fallback for empty display name',
        (tester) async {
      await pumpTile(
        tester,
        conversation: conversation(
          customParticipant: const ParticipantEntity(
            id: 'user-1',
            displayName: '',
            handle: 'listener',
            avatarUrl: null,
          ),
        ),
      );

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('calls onTap when tile is tapped', (tester) async {
      var tapped = false;

      await pumpTile(
        tester,
        conversation: conversation(),
        onTap: () => tapped = true,
      );

      await tester.tap(find.byType(ConversationTile));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('calls onMorePressed when action button is tapped',
        (tester) async {
      var morePressed = false;

      await pumpTile(
        tester,
        conversation: conversation(),
        onMorePressed: () => morePressed = true,
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();

      expect(morePressed, isTrue);
    });
  });
}
