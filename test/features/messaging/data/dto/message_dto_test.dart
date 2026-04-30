import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/messaging/data/dto/message_dto.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_type.dart';

void main() {
  group('MessageDto', () {
    Map<String, dynamic> sharedTrackJson() {
      return <String, dynamic>{
        'id': 'track-1',
        'title': 'Track One',
        'artist': 'Artist One',
        'artworkUrl': 'https://example.com/track.png',
      };
    }

    Map<String, dynamic> sharedPlaylistJson() {
      return <String, dynamic>{
        'id': 'playlist-1',
        'title': 'Playlist One',
        'tracksCount': 10,
        'artworkUrl': 'https://example.com/playlist.png',
      };
    }

    test('fromJson reads camelCase fields', () {
      final dto = MessageDto.fromJson(<String, dynamic>{
        'id': 'message-1',
        'conversationId': 'conversation-1',
        'senderId': 'sender-1',
        'receiverId': 'receiver-1',
        'type': 'TEXT',
        'text': 'Hello',
        'isRead': true,
        'createdAt': '2026-04-30T10:00:00.000Z',
      });

      expect(dto.id, 'message-1');
      expect(dto.conversationId, 'conversation-1');
      expect(dto.senderId, 'sender-1');
      expect(dto.receiverId, 'receiver-1');
      expect(dto.type, MessageType.text);
      expect(dto.text, 'Hello');
      expect(dto.isRead, isTrue);
      expect(dto.createdAt, DateTime.parse('2026-04-30T10:00:00.000Z'));
      expect(dto.sharedTrack, isNull);
      expect(dto.sharedPlaylist, isNull);
    });

    test('fromJson reads fallback id and snake_case fields', () {
      final dto = MessageDto.fromJson(<String, dynamic>{
        '_id': 'message-2',
        'conversation_id': 'conversation-2',
        'sender_id': 'sender-2',
        'receiver_id': 'receiver-2',
        'type': 'text',
        'text': 'Hi',
        'is_read': '1',
        'created_at': '2026-04-30T11:00:00.000Z',
      });

      expect(dto.id, 'message-2');
      expect(dto.conversationId, 'conversation-2');
      expect(dto.senderId, 'sender-2');
      expect(dto.receiverId, 'receiver-2');
      expect(dto.type, MessageType.text);
      expect(dto.text, 'Hi');
      expect(dto.isRead, isTrue);
      expect(dto.createdAt, DateTime.parse('2026-04-30T11:00:00.000Z'));
    });

    test('fromJson reads messageId fallback', () {
      final dto = MessageDto.fromJson(<String, dynamic>{
        'messageId': 'message-3',
      });

      expect(dto.id, 'message-3');
    });

    test('fromJson trims nullable string fields and converts blanks to null',
        () {
      final dto = MessageDto.fromJson(<String, dynamic>{
        'senderId': '  sender-1  ',
        'receiverId': '   ',
        'text': '  Hello  ',
      });

      expect(dto.senderId, 'sender-1');
      expect(dto.receiverId, isNull);
      expect(dto.text, 'Hello');
    });

    test('fromJson converts bool-like values', () {
      final trueFromString = MessageDto.fromJson(<String, dynamic>{
        'isRead': 'true',
      });

      final trueFromNumber = MessageDto.fromJson(<String, dynamic>{
        'isRead': 1,
      });

      final falseFromString = MessageDto.fromJson(<String, dynamic>{
        'isRead': 'false',
      });

      final falseFromNumber = MessageDto.fromJson(<String, dynamic>{
        'isRead': 0,
      });

      final invalidDefaultsFalse = MessageDto.fromJson(<String, dynamic>{
        'isRead': 'maybe',
      });

      expect(trueFromString.isRead, isTrue);
      expect(trueFromNumber.isRead, isTrue);
      expect(falseFromString.isRead, isFalse);
      expect(falseFromNumber.isRead, isFalse);
      expect(invalidDefaultsFalse.isRead, isFalse);
    });

    test('fromJson defaults invalid and missing createdAt to unix epoch utc',
        () {
      final invalid = MessageDto.fromJson(<String, dynamic>{
        'createdAt': 'not-a-date',
      });

      final missing = MessageDto.fromJson(<String, dynamic>{});

      final epoch = DateTime.fromMillisecondsSinceEpoch(0).toUtc();

      expect(invalid.createdAt, epoch);
      expect(missing.createdAt, epoch);
    });

    test('fromJson parses sharedTrack when it is a map', () {
      final dto = MessageDto.fromJson(<String, dynamic>{
        'id': 'message-track',
        'type': 'track',
        'sharedTrack': sharedTrackJson(),
      });

      expect(dto.sharedTrack, isNotNull);
      expect(dto.sharedTrack!.id, 'track-1');
      expect(dto.sharedPlaylist, isNull);
    });

    test('fromJson parses sharedPlaylist when it is a map', () {
      final dto = MessageDto.fromJson(<String, dynamic>{
        'id': 'message-playlist',
        'type': 'playlist',
        'sharedPlaylist': sharedPlaylistJson(),
      });

      expect(dto.sharedPlaylist, isNotNull);
      expect(dto.sharedPlaylist!.id, 'playlist-1');
      expect(dto.sharedTrack, isNull);
    });

    test('fromJson ignores invalid sharedTrack and sharedPlaylist values', () {
      final dto = MessageDto.fromJson(<String, dynamic>{
        'sharedTrack': 'not-a-map',
        'sharedPlaylist': <String>['not-a-map'],
      });

      expect(dto.sharedTrack, isNull);
      expect(dto.sharedPlaylist, isNull);
    });

    test('fromJson defaults missing fields safely', () {
      final dto = MessageDto.fromJson(<String, dynamic>{});

      expect(dto.id, '');
      expect(dto.conversationId, '');
      expect(dto.senderId, isNull);
      expect(dto.receiverId, isNull);
      expect(dto.text, isNull);
      expect(dto.isRead, isFalse);
      expect(dto.type, isNotNull);
    });

    test('toEntity maps all fields', () {
      final dto = MessageDto.fromJson(<String, dynamic>{
        'id': 'message-1',
        'conversationId': 'conversation-1',
        'senderId': 'sender-1',
        'receiverId': 'receiver-1',
        'type': 'TEXT',
        'text': 'Hello',
        'isRead': true,
        'createdAt': '2026-04-30T10:00:00.000Z',
        'sharedTrack': sharedTrackJson(),
        'sharedPlaylist': sharedPlaylistJson(),
      });

      final entity = dto.toEntity();

      expect(entity.id, dto.id);
      expect(entity.conversationId, dto.conversationId);
      expect(entity.senderId, dto.senderId);
      expect(entity.receiverId, dto.receiverId);
      expect(entity.type, dto.type);
      expect(entity.text, dto.text);
      expect(entity.isRead, dto.isRead);
      expect(entity.createdAt, dto.createdAt);
      expect(entity.sharedTrack, isNotNull);
      expect(entity.sharedPlaylist, isNotNull);
    });
  });
}
