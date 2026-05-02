import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/config/app_config.dart';

void main() {
  group('AppConfig constants', () {
    test('appEnv has a value', () {
      expect(AppConfig.appEnv, isNotNull);
      expect(AppConfig.appEnv, isNotEmpty);
    });

    test('isLocal and isProduction are mutually exclusive', () {
      expect(AppConfig.isLocal && AppConfig.isProduction, false);
    });

    test('isProduction is true when appEnv uses the default value', () {
      expect(AppConfig.appEnv, 'production');
      expect(AppConfig.isProduction, true);
      expect(AppConfig.isLocal, false);
    });

    test('useMockTrackManagement has a value', () {
      expect(AppConfig.useMockTrackManagement, isNotNull);
    });

    test('mockTrackManagementMode has a value', () {
      expect(AppConfig.mockTrackManagementMode, isNotNull);
      expect(AppConfig.mockTrackManagementMode, isNotEmpty);
    });

    test('recaptchaWindowsWebUrl is a valid URL', () {
      final url = Uri.tryParse(AppConfig.recaptchaWindowsWebUrl);
      expect(url, isNotNull);
      expect(url!.hasScheme, true);
    });

    test('recaptchaAndroidSiteKey is not empty', () {
      expect(AppConfig.recaptchaAndroidSiteKey, isNotEmpty);
    });

    test('apiUrl returns non-empty string', () {
      expect(AppConfig.apiUrl, isNotEmpty);
    });

    test('apiUrl is a non-empty string', () {
      final url = AppConfig.apiUrl;
      expect(url, isA<String>());
      expect(url.isNotEmpty, true);
    });
  });
}
