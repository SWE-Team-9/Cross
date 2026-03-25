import 'package:flutter/material.dart';
import 'package:soundcloud_clone/features/profile/presentation/routes/profile_routes.dart';

/// Wraps any widget with a tap that navigates to the correct user profile.
/// Use this everywhere avatars or usernames appear so all profile
/// navigation goes through one consistent entry point.
///
/// Usage:
/// ```dart
/// // Tappable avatar
/// UserTapTarget(
///   userId: user.id,
///   child: CircleAvatar(backgroundImage: NetworkImage(user.avatarUrl)),
/// )
///
/// // Tappable username
/// UserTapTarget(
///   userId: user.id,
///   child: Text(user.username),
/// )
/// ```
class UserTapTarget extends StatelessWidget {
  final String userId;
  final Widget child;

  const UserTapTarget({
    super.key,
    required this.userId,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ProfileRoutes.goToProfile(context, userId),
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}
