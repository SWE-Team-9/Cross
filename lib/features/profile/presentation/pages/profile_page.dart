import 'package:flutter/material.dart';

/// Profile page stub.
/// Route: /profile/:userId
///
/// TODO (Abdallah — T2.3): Replace stub body with full profile UI.
/// Fields: avatar, cover image, bio, location, social links, stats,
/// track/playlist/likes tabs, follow button, own-profile vs other-user states.
class ProfilePage extends StatelessWidget {
  final String userId;

  const ProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
      ),
      // TODO: Abdallah — replace with full profile UI (T2.3)
      body: Center(
        child: Text(
          'Profile: $userId',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}