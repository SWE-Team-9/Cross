import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/services/update_service.dart';

void main() {
  group('UpdateService', () {
    test('detects mandatory updates when minimum version is newer', () {
      expect(
        UpdateService.isMandatoryUpdate(
          {'min_required_version': '1.2.0'},
          '1.1.9',
        ),
        isTrue,
      );
    });

    test('does not require updates for equal or older minimum versions', () {
      expect(
        UpdateService.isMandatoryUpdate(
          {'min_required_version': '1.2.0'},
          '1.2.0',
        ),
        isFalse,
      );
      expect(
        UpdateService.isMandatoryUpdate(
          {'min_required_version': '1.1.9'},
          '1.2.0',
        ),
        isFalse,
      );
    });
  });
}
