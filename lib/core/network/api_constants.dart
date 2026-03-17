class ApiConstants {
  // Base URLs - should come from environment config
  static const String baseUrlDev = 'https://dev-api.soundcloud.com';
  static const String baseUrlStaging = 'https://staging-api.soundcloud.com';
  static const String baseUrlProd = 'https://api.soundcloud.com';

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String verifyEmail = '/auth/verify';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // User endpoints
  static const String profile = '/users/profile';
  static const String updateProfile = '/users/update';
  static const String uploadAvatar = '/users/avatar';

  // Track endpoints
  static const String tracks = '/tracks';
  static const String uploadTrack = '/tracks/upload';
  static const String trackDetail = '/tracks';
  static const String likeTrack = '/tracks/like';

  // Social endpoints
  static const String follow = '/users/follow';
  static const String followers = '/users/followers';
  static const String following = '/users/following';
  static const String block = '/users/block';

  // Add more as needed
}
