import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Named route paths and navigation helpers for the profile feature.
/// Import this anywhere you need to navigate to a profile screen.
///
/// Usage:
/// ```dart
/// ProfileRoutes.goToProfile(context, userId);
/// ProfileRoutes.goToFollowers(context, userId);
/// ```
abstract class ProfileRoutes {
  // ── Route path constants ──────────────────────────────────────────────────
  static const String profile     = '/profile/:userId';
  static const String editProfile = '/profile/edit';
  static const String followers   = '/followers/:userId';
  static const String following   = '/following/:userId';

  // ── Navigation helpers ────────────────────────────────────────────────────
  // Use these instead of hardcoding path strings across the app.

  static void goToProfile(BuildContext context, String userId) =>
      context.push('/profile/$userId');

  static void goToEditProfile(BuildContext context) =>
      context.push('/profile/edit');

  static void goToFollowers(BuildContext context, String userId) =>
      context.push('/followers/$userId');

  static void goToFollowing(BuildContext context, String userId) =>
      context.push('/following/$userId');
}