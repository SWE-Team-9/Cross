class AppConfig {
  const AppConfig._();

  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:3006',
  );

  static const bool useMockTrackManagement = bool.fromEnvironment(
    'USE_MOCK_TRACK_MANAGEMENT',
    defaultValue: false,
  );

  static const String mockTrackManagementMode = String.fromEnvironment(
    'MOCK_TRACK_MANAGEMENT_MODE',
    defaultValue: 'success',
  );

  static const String recaptchaAndroidSiteKey = String.fromEnvironment(
    'RECAPTCHA_ANDROID_SITE_KEY',
    defaultValue: '6LcxwJYsAAAAAOOjnV1K6O-Sx7hx02ltn85ugKK5',
  );

  static const String recaptchaWindowsWebUrl = String.fromEnvironment(
    'RECAPTCHA_WINDOWS_WEB_URL',
    defaultValue: 'https://inquisitive-seahorse-5af208.netlify.app',
  );
}
