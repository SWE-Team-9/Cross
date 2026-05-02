import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/notifications/data/services/fcm_registration_service.dart';

void main() {
  group('FcmRegistrationService static helpers', () {
    test('_normalizeKind converts to lowercase', () {
      expect(FcmRegistrationService.normalizeKind('LIKE'), 'like');
      expect(FcmRegistrationService.normalizeKind('Comment'), 'comment');
      expect(FcmRegistrationService.normalizeKind(''), '');
      expect(FcmRegistrationService.normalizeKind(null), '');
    });

    test('_looksLikeMessageKind identifies message types', () {
      expect(FcmRegistrationService.looksLikeMessageKind('message'), true);
      expect(FcmRegistrationService.looksLikeMessageKind('new_message'), true);
      expect(FcmRegistrationService.looksLikeMessageKind('direct_message'), true);
      expect(FcmRegistrationService.looksLikeMessageKind('like'), false);
      expect(FcmRegistrationService.looksLikeMessageKind('comment'), false);
    });

    test('_firstNonEmpty returns first non-empty value', () {
      expect(
        FcmRegistrationService.firstNonEmpty(['', 'second', 'third']),
        'second',
      );
      expect(
        FcmRegistrationService.firstNonEmpty(['first']),
        'first',
      );
      expect(
        FcmRegistrationService.firstNonEmpty([null, '', 'value']),
        'value',
      );
      expect(
        FcmRegistrationService.firstNonEmpty([]),
        '',
      );
    });

    test('_extractConversationId extracts from map', () {
      final map = {'conversationId': 'conv-123'};
      expect(
        FcmRegistrationService.extractConversationId(map),
        'conv-123',
      );

      final map2 = {'conversation_id': 'conv-456'};
      expect(
        FcmRegistrationService.extractConversationId(map2),
        'conv-456',
      );

      final map3 = {'id': 'conv-789'};
      expect(
        FcmRegistrationService.extractConversationId(map3),
        'conv-789',
      );

      expect(
        FcmRegistrationService.extractConversationId('not a map'),
        '',
      );
    });
  });
}
