import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_type.dart';

void main() {
  group('MessageTypeX', () {
    group('fromApi', () {
      test('parses TEXT', () {
        expect(MessageTypeX.fromApi('TEXT'), MessageType.text);
      });

      test('parses TRACK_SHARE', () {
        expect(MessageTypeX.fromApi('TRACK_SHARE'), MessageType.trackShare);
      });

      test('parses PLAYLIST_SHARE', () {
        expect(
          MessageTypeX.fromApi('PLAYLIST_SHARE'),
          MessageType.playlistShare,
        );
      });

      test('trims and uppercases raw value', () {
        expect(MessageTypeX.fromApi(' text '), MessageType.text);
        expect(MessageTypeX.fromApi(' track_share '), MessageType.trackShare);
        expect(
          MessageTypeX.fromApi(' playlist_share '),
          MessageType.playlistShare,
        );
      });

      test('returns unknown for null, empty, or unsupported values', () {
        expect(MessageTypeX.fromApi(null), MessageType.unknown);
        expect(MessageTypeX.fromApi(''), MessageType.unknown);
        expect(MessageTypeX.fromApi('OTHER'), MessageType.unknown);
        expect(MessageTypeX.fromApi(123), MessageType.unknown);
      });
    });

    group('apiValue', () {
      test('returns API value for every enum value', () {
        expect(MessageType.text.apiValue, 'TEXT');
        expect(MessageType.trackShare.apiValue, 'TRACK_SHARE');
        expect(MessageType.playlistShare.apiValue, 'PLAYLIST_SHARE');
        expect(MessageType.unknown.apiValue, 'UNKNOWN');
      });
    });

    group('isShare', () {
      test('is true only for share message types', () {
        expect(MessageType.text.isShare, isFalse);
        expect(MessageType.trackShare.isShare, isTrue);
        expect(MessageType.playlistShare.isShare, isTrue);
        expect(MessageType.unknown.isShare, isFalse);
      });
    });
  });
}
