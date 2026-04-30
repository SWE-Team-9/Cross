import 'dart:io' show Platform;

class AppConfig {
  const AppConfig._();

  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'production',
  );

  static bool get isLocal => appEnv == 'local';
  static bool get isProduction => appEnv == 'production';

  /// IMPORTANT:
  /// Keep this as ROOT origin only.
  /// ApiConstants already appends `/api/v1/...`.
  static String get apiUrl {
    const override = String.fromEnvironment('API_URL', defaultValue: '');
    if (override.isNotEmpty) {
      return _stripTrailingSlash(_stripApiV1Suffix(override));
    }

    return 'https://dev.iqa3.tech';
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
    const override = String.fromEnvironment(
      'RECAPTCHA_ANDROID_SITE_KEY',
      defaultValue: '',
    );
    if (override.isNotEmpty) {
      return override;
    }

    return '6LcxwJYsAAAAAOOjnV1K6O-Sx7hx02ltn85ugKK5';
  }

  static const String recaptchaWindowsWebUrl = String.fromEnvironment(
    'RECAPTCHA_WINDOWS_WEB_URL',
    defaultValue: 'https://inquisitive-seahorse-5af208.netlify.app',
  );

  // ── OAuth (Native App) ──────────────────────────────────────────────────

  static const String oauthClientId = String.fromEnvironment(
    'OAUTH_CLIENT_ID',
    defaultValue: 'soundclone-native-app',
  );

  static const String oauthScope = String.fromEnvironment(
    'OAUTH_SCOPE',
    defaultValue: 'read write',
  );

  static const String oauthAndroidRedirectUri = String.fromEnvironment(
    'OAUTH_ANDROID_REDIRECT_URI',
    defaultValue: 'soundclone://oauth/callback',
  );

  static const String oauthWindowsRedirectUri = String.fromEnvironment(
    'OAUTH_WINDOWS_REDIRECT_URI',
    defaultValue: 'http://127.0.0.1:8080/oauth/callback',
  );

  static String get oauthRedirectUri {
    if (Platform.isWindows) return oauthWindowsRedirectUri;
    return oauthAndroidRedirectUri;
  }

  static String _stripTrailingSlash(String value) {
    if (value.endsWith('/')) {
      return value.substring(0, value.length - 1);
    }
    return value;
  }

  static String _stripApiV1Suffix(String value) {
    final normalized = value.trim();
    if (normalized.endsWith('/api/v1')) {
      return normalized.substring(0, normalized.length - '/api/v1'.length);
    }
    return normalized;
  }
}
