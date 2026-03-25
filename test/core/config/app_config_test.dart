import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/config/app_config.dart';

void main() {
  test('AppConfig can be referenced', () {
    expect(AppConfig.apiUrl, isNotNull);
  });
}
