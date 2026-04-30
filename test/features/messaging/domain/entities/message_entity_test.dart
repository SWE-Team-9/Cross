import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_type.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/shared_playlist_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/shared_track_entity.dart';

void main() {
  group('MessageEntity', () {
    final createdAt = DateTime.utc(2026, 4, 30, 10);

    const sharedTrack = SharedTrackEntity(
      id: 'track-1',
      title: 'Track One',
      artist: 'Artist One',
      artworkUrl: 'https://example.com/track.png',
    );

    const sharedPlaylist = SharedPlaylistEntity(
      id: 'playlist-1',
      title: 'Playlist One',
      tracksCount: 8,
      artworkUrl: 'https://example.com/playlist.png',
    );

    test('stores all provided values', () {
      final entity = MessageEntity(
        id: 'message-1',
        conversationId: 'conversation-1',
        senderId: 'sender-1',
        receiverId: 'receiver-1',
        type: MessageType.text,
        text: 'Hello',
        isRead: true,
        createdAt: createdAt,
        sharedTrack: null,
        sharedPlaylist: null,
      );

      expect(entity.id, 'message-1');
      expect(entity.conversationId, 'conversation-1');
      expect(entity.senderId, 'sender-1');
      expect(entity.receiverId, 'receiver-1');
      expect(entity.type, MessageType.text);
      expect(entity.text, 'Hello');
      expect(entity.isRead, isTrue);
      expect(entity.createdAt, createdAt);
      expect(entity.sharedTrack, isNull);
      expect(entity.sharedPlaylist, isNull);
    });

    test('allows nullable senderId, receiverId, and text', () {
      final entity = MessageEntity(
        id: 'message-1',
        conversationId: 'conversation-1',
        senderId: null,
        receiverId: null,
        type: MessageType.unknown,
        text: null,
        isRead: false,
        createdAt: createdAt,
        sharedTrack: null,
        sharedPlaylist: null,
      );

      expect(entity.senderId, isNull);
      expect(entity.receiverId, isNull);
      expect(entity.text, isNull);
    });

    test('isText is true only for text messages', () {
      final textMessage = MessageEntity(
        id: 'message-1',
        conversationId: 'conversation-1',
        senderId: 'sender-1',
        receiverId: 'receiver-1',
        type: MessageType.text,
        text: 'Hello',
        isRead: false,
        createdAt: createdAt,
        sharedTrack: null,
        sharedPlaylist: null,
      );

      final trackMessage = MessageEntity(
        id: 'message-2',
        conversationId: 'conversation-1',
        senderId: 'sender-1',
        receiverId: 'receiver-1',
        type: MessageType.trackShare,
        text: null,
        isRead: false,
        createdAt: createdAt,
        sharedTrack: sharedTrack,
        sharedPlaylist: null,
      );

      expect(textMessage.isText, isTrue);
      expect(trackMessage.isText, isFalse);
    });

    test('isTrackShare is true only for track share messages', () {
      final entity = MessageEntity(
        id: 'message-1',
        conversationId: 'conversation-1',
        senderId: 'sender-1',
        receiverId: 'receiver-1',
        type: MessageType.trackShare,
        text: null,
        isRead: false,
        createdAt: createdAt,
        sharedTrack: sharedTrack,
        sharedPlaylist: null,
      );

      expect(entity.isTrackShare, isTrue);
      expect(entity.isText, isFalse);
      expect(entity.isPlaylistShare, isFalse);
      expect(entity.sharedTrack, sharedTrack);
    });

    test('isPlaylistShare is true only for playlist share messages', () {
      final entity = MessageEntity(
        id: 'message-1',
        conversationId: 'conversation-1',
        senderId: 'sender-1',
        receiverId: 'receiver-1',
        type: MessageType.playlistShare,
        text: null,
        isRead: false,
        createdAt: createdAt,
        sharedTrack: null,
        sharedPlaylist: sharedPlaylist,
      );

      expect(entity.isPlaylistShare, isTrue);
      expect(entity.isText, isFalse);
      expect(entity.isTrackShare, isFalse);
      expect(entity.sharedPlaylist, sharedPlaylist);
    });
  });
}
