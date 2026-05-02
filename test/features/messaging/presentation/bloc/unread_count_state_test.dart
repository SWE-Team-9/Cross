import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/messaging/presentation/bloc/unread_count_state.dart';

void main() {
  group('UnreadCountState', () {
    test('initial has expected defaults', () {
      final state = UnreadCountState.initial();

      expect(state.isLoading, isFalse);
      expect(state.count, 0);
      expect(state.errorMessage, isNull);
    });

    test('copyWith keeps existing values when no values are provided', () {
      const original = UnreadCountState(
        isLoading: true,
        count: 10,
        errorMessage: 'error',
      );

      final copy = original.copyWith();

      expect(copy.isLoading, original.isLoading);
      expect(copy.count, original.count);
      expect(copy.errorMessage, original.errorMessage);
    });

    test('copyWith overrides provided values', () {
      final original = UnreadCountState.initial();

      final copy = original.copyWith(
        isLoading: true,
        count: 5,
        errorMessage: 'error',
      );

      expect(copy.isLoading, isTrue);
      expect(copy.count, 5);
      expect(copy.errorMessage, 'error');
    });

    test('copyWith clearError clears errorMessage', () {
      const original = UnreadCountState(
        isLoading: false,
        count: 5,
        errorMessage: 'error',
      );

      final copy = original.copyWith(clearError: true);

      expect(copy.errorMessage, isNull);
    });
  });
}
