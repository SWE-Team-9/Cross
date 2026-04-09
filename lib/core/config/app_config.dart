import 'dart:io' show Platform;

class AppConfig {
  const AppConfig._();

  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'local',
  );

  static bool get isLocal => appEnv == 'local';
  static bool get isProduction => appEnv == 'production';

  static String get apiUrl {
    const override = String.fromEnvironment('API_URL', defaultValue: '');
    if (override.isNotEmpty) return override;

    if (isProduction) return 'https://iqa3.tech';

    // dev
    if (Platform.isAndroid) return 'https://iqa3.tech';
    if (Platform.isIOS) return 'http://localhost:3006';
    return 'http://127.0.0.1:3006/api/v1';
  }

  static const bool useMockTrackManagement = bool.fromEnvironment(
    'USE_MOCK_TRACK_MANAGEMENT',
    defaultValue: false,
  );

  static const String mockTrackManagementMode = String.fromEnvironment(
    'MOCK_TRACK_MANAGEMENT_MODE',
    defaultValue: 'success',
  );

  static String get recaptchaAndroidSiteKey {
    if (isProduction) {
      return '6LcPd5EsAAAAAO8YOCSJJJr3PmX_lBzPaF-SvxR7';
    }
    return '6LcPd5EsAAAAAO8YOCSJJJr3PmX_lBzPaF-SvxR7';
  }

  static const String recaptchaWindowsWebUrl = String.fromEnvironment(
    'RECAPTCHA_WINDOWS_WEB_URL',
    defaultValue: 'https://inquisitive-seahorse-5af208.netlify.app',
  );
}
