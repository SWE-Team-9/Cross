import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/utils/platform_url_utils.dart';

void main() {
  group('PlatformUrlUtils.normalizeBackendUrl', () {
    test('returns null when url is null', () {
      expect(PlatformUrlUtils.normalizeBackendUrl(null), isNull);
    });

    test('returns null when url is empty', () {
      expect(PlatformUrlUtils.normalizeBackendUrl(''), isNull);
    });

    test('returns same url for non-empty value on non-Windows-safe assertion path', () {
      const url = 'http://127.0.0.1:3006/uploads/avatar.png';
      final result = PlatformUrlUtils.normalizeBackendUrl(url);

      expect(result, isNotNull);
      expect(result, contains('/uploads/avatar.png'));
    });
  });
}