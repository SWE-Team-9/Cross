import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Named route paths and navigation helpers for the profile feature.
/// Import this anywhere you need to navigate to a profile screen.
///
/// Usage:
/// ```dart
/// ProfileRoutes.goToProfile(context, handle);
/// ProfileRoutes.goToFollowers(context, handle);
/// ```
abstract class ProfileRoutes {
  // ── Route path constants ──────────────────────────────────────────────────
  static const String profile = '/profile/:handle';
  static const String editProfile = '/profile/edit';
  static const String followers = '/followers/:handle';
  static const String following = '/following/:handle';

  // ── Navigation helpers ────────────────────────────────────────────────────
  // Use these instead of hardcoding path strings across the app.

  static void goToProfile(BuildContext context, String handle) =>
      context.push('/profile/$handle');

  static void goToEditProfile(BuildContext context) =>
      context.push('/profile/edit');

  static void goToFollowers(BuildContext context, String handle) =>
      context.push('/followers/$handle');

  static void goToFollowing(BuildContext context, String handle) =>
      context.push('/following/$handle');
}
