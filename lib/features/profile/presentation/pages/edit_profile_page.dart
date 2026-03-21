import 'package:flutter/material.dart';

/// Edit profile page stub.
/// Route: /profile/edit
///
/// TODO (Abdallah — T2.4): Replace with editable fields, validation,
/// save/cancel handling, discard confirmation dialog, success/error feedback.
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title:
            const Text('Edit Profile', style: TextStyle(color: Colors.white)),
      ),
      // TODO: Abdallah — replace with edit form (T2.4)
      body: const Center(
        child: Text(
          'Edit Profile — coming soon',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
