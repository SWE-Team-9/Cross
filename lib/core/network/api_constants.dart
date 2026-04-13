import '../config/app_config.dart';

abstract class ApiConstants {
  static String get baseUrl => AppConfig.apiUrl;

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
  static const String sessions = '$authBase/sessions';

  // ── OAuth ───────────────────────────────────────────────────────────────
  static const String oauthBase = '/api/v1/oauth';
  static const String oauthAuthorize = '$oauthBase/authorize';
  static const String oauthToken = '$oauthBase/token';
  static const String oauthRevoke = '$oauthBase/revoke';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  // ── Profiles ────────────────────────────────────────────────────────────
  static const String profilesBase = '/api/v1/profiles';
  static const String myProfile = '$profilesBase/me';
  static const String profileImages = '$profilesBase/me/images';
  static const String checkHandle = '$profilesBase/check-handle';
  static const String profileLinks = '$profilesBase/me/links';

  static String profileByHandlePath(String handle) => '$profilesBase/$handle';

  // ── Social graph ────────────────────────────────────────────────────────
  static const String socialBase = '/api/v1/social';

  static String followersPath(String userId) => '$socialBase/$userId/followers';
  static String followingPath(String userId) => '$socialBase/$userId/following';
  static String followUserPath(String userId) => '$socialBase/follow/$userId';
  static String blockUserPath(String userId) => '$socialBase/block/$userId';
  static const String blockedUsersPath = '$socialBase/blocked-users';

  // ── Tracks ──────────────────────────────────────────────────────────────
  static const String tracks = '/api/v1/tracks';
  static const String users = '/api/v1/users';

  static String trackByIdPath(String trackId) => '$tracks/$trackId';
  static String trackStatusPath(String trackId) =>
      '${trackByIdPath(trackId)}/status';
  static String trackWaveformPath(String trackId) =>
      '${trackByIdPath(trackId)}/waveform';
  static String userTracksPath(String userId) => '$users/$userId/tracks';

  // ── Interactions ────────────────────────────────────────────────────────
  static const String interactionsBase = '/api/v1/interactions';
  static const String commentsBase = '$interactionsBase/comments';

  static String likeTrackPath(String trackId) =>
      '$interactionsBase/tracks/$trackId/like';

  static String repostTrackPath(String trackId) =>
      '$interactionsBase/tracks/$trackId/repost';

  static String trackInteractionStatusPath(String trackId) =>
      '$interactionsBase/tracks/$trackId/status';

  static String trackCommentsPath(String trackId) =>
      '$interactionsBase/tracks/$trackId/comments';

  static String commentByIdPath(String commentId) => '$commentsBase/$commentId';

  static String trackLikersPath(String trackId) =>
      '$interactionsBase/tracks/$trackId/likers';

  static String trackRepostersPath(String trackId) =>
      '$interactionsBase/tracks/$trackId/reposters';
  static const String myLikedTracks = '/api/v1/interactions/me/likes';
  static const String myRepostedTracks = '/api/v1/interactions/me/reposts';
}