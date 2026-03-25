// Dart SDK

// Flutter
// Third-party
// Project
import '../config/app_config.dart';

abstract class ApiConstants {
  static const String baseUrl = AppConfig.apiUrl;

  // ── Auth (not your task — keeping for reference) ───────────────────────
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
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
  // ── Profiles (T2.3 + T2.4) ────────────────────────────────────────────
  // GET    /profiles/:handle          → fetch any profile by handle
  // PATCH  /profiles/me               → update own profile fields
  // POST   /profiles/me/images/avatar → upload avatar
  // POST   /profiles/me/images/cover  → upload cover photo
  // GET    /profiles/check-handle     → check handle availability
  // DELETE /profiles/me               → deactivate account
  // ── Profiles ────────────────────────────────────────────────────────────
  static const String profilesBase = '/api/v1/profiles';
  static const String myProfile = '$profilesBase/me';
  static const String profileImages =
      '$profilesBase/me/images'; // append /avatar or /cover
  static const String checkHandle = '$profilesBase/check-handle';

  static String profileByHandlePath(String handle) => '$profilesBase/$handle';
  // ── Social graph (T2.9, T2.10, T2.11 — Ahmed Reda) ────────────────────
  // POST   /social/follow/:userId
  // DELETE /social/follow/:userId
  // GET    /social/:userId/followers
  // GET    /social/:userId/following
  // POST   /social/block/:userId
  // DELETE /social/block/:userId
  // ── Social graph ────────────────────────────────────────────────────────
  static const String socialBase = '/api/v1/social';

  static String followersPath(String userId) => '$socialBase/$userId/followers';
  static String followingPath(String userId) => '$socialBase/$userId/following';
  static String followUserPath(String userId) => '$socialBase/follow/$userId';
  static String blockUserPath(String userId) => '$socialBase/block/$userId';
  // ── Tracks (Sprint 3+) ─────────────────────────────────────────────────
  static const String tracks = '/tracks';
  static const String userTracks = '/users'; // append /:userId/tracks
}
