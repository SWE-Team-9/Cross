// Dart SDK

// Flutter
// Third-party
// Project
import '../config/app_config.dart';

abstract class ApiConstants {
  static const String baseUrl = AppConfig.apiUrl;

  // ── Auth (not your task — keeping for reference) ───────────────────────
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String verifyEmail = '/auth/verify-email';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String currentUser = '/auth/me';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
  // ── Profiles (T2.3 + T2.4) ────────────────────────────────────────────
  // GET    /profiles/:handle          → fetch any profile by handle
  // PATCH  /profiles/me               → update own profile fields
  // POST   /profiles/me/images/avatar → upload avatar
  // POST   /profiles/me/images/cover  → upload cover photo
  // GET    /profiles/check-handle     → check handle availability
  // DELETE /profiles/me               → deactivate account
  static const String profileByHandle = '/profiles'; // append /:handle
  static const String myProfile = '/profiles/me';
  static const String profileImages =
      '/profiles/me/images'; // append /avatar or /cover
  static const String checkHandle = '/profiles/check-handle';

  // ── Social graph (T2.9, T2.10, T2.11 — Ahmed Reda) ────────────────────
  // POST   /social/follow/:userId
  // DELETE /social/follow/:userId
  // GET    /social/:userId/followers
  // GET    /social/:userId/following
  // POST   /social/block/:userId
  // DELETE /social/block/:userId
  static const String socialBase = '/social';

  // ── Tracks (Sprint 3+) ─────────────────────────────────────────────────
  static const String tracks = '/tracks';
  static const String userTracks = '/users'; // append /:userId/tracks
}
