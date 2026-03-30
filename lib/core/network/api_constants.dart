import '../config/app_config.dart';

abstract class ApiConstants {
  static const String baseUrl = AppConfig.apiUrl;

  // ── Auth ────────────────────────────────────────────────────────────────
  static const String authBase = '/api/v1/auth';

  static const String login = '$authBase/login';
  static const String register = '$authBase/register';
  static const String logout = '$authBase/logout';
  static const String refreshToken = '$authBase/refresh';
  static const String verifyEmail = '$authBase/verify-email';
  static const String forgotPassword = '$authBase/forgot-password';
  static const String resetPassword = '$authBase/reset-password';
  static const String currentUser = '$authBase/me';
  static const String resendVerification = '$authBase/resend-verification';
  static const String emailChange = '$authBase/email/change';
  static const String confirmEmailChange = '$authBase/email/confirm-change';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  // ── Profiles ────────────────────────────────────────────────────────────
  static const String profilesBase = '/api/v1/profiles';
  static const String myProfile = '$profilesBase/me';
  static const String profileImages =
      '$profilesBase/me/images'; // append /avatar or /cover
  static const String checkHandle = '$profilesBase/check-handle';

  static String profileByHandlePath(String handle) => '$profilesBase/$handle';

  // ── Social graph ────────────────────────────────────────────────────────
  static const String socialBase = '/api/v1/social';

  static String followersPath(String userId) => '$socialBase/$userId/followers';
  static String followingPath(String userId) => '$socialBase/$userId/following';
  static String followUserPath(String userId) => '$socialBase/follow/$userId';
  static String blockUserPath(String userId) => '$socialBase/block/$userId';

  // ── Tracks ──────────────────────────────────────────────────────────────
  static const String tracks = '/tracks';
  static const String userTracks = '/users'; // append /:userId/tracks
}