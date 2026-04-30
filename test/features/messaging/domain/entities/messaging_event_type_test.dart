import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/messaging_event_type.dart';

void main() {
  group('MessagingEventTypeX', () {
    group('fromApi', () {
      test('parses NEW_MESSAGE', () {
        expect(
          MessagingEventTypeX.fromApi('NEW_MESSAGE'),
          MessagingEventType.newMessage,
        );
      });

      test('trims and uppercases raw value', () {
        expect(
          MessagingEventTypeX.fromApi(' new_message '),
          MessagingEventType.newMessage,
        );
      });

      test('returns unknown for null, empty, or unsupported values', () {
        expect(MessagingEventTypeX.fromApi(null), MessagingEventType.unknown);
        expect(MessagingEventTypeX.fromApi(''), MessagingEventType.unknown);
        expect(
            MessagingEventTypeX.fromApi('OTHER'), MessagingEventType.unknown);
        expect(MessagingEventTypeX.fromApi(123), MessagingEventType.unknown);
      });
    });

    group('apiValue', () {
      test('returns API value for every enum value', () {
        expect(MessagingEventType.newMessage.apiValue, 'NEW_MESSAGE');
        expect(MessagingEventType.unknown.apiValue, 'UNKNOWN');
      });
    });
  });
}
