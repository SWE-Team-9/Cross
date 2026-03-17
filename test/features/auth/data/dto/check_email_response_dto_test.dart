import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/auth/data/dto/check_email_response_dto.dart';

void main() {
  group('CheckEmailResponseDto', () {
    test('fromJson returns true when exists is true', () {
      final result = CheckEmailResponseDto.fromJson({
        'exists': true,
      });

      expect(result.exists, true);
    });

    test('fromJson returns false when exists is false', () {
      final result = CheckEmailResponseDto.fromJson({
        'exists': false,
      });

      expect(result.exists, false);
    });

    test('fromJson returns false when exists is missing', () {
      final result = CheckEmailResponseDto.fromJson({});

      expect(result.exists, false);
    });
  });
}
