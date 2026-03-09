import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Sample Tests', () {
    test('True should be true', () {
      expect(true, isTrue);
    });

    test('False should be false', () {
      expect(false, isFalse);
    });

    test('1 + 1 should equal 2', () {
      expect(1 + 1, 2);
    });
  });
}
