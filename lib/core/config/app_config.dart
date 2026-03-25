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
}
