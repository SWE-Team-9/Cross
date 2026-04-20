import 'package:flutter/material.dart';

class DeleteTrackConfirmationDialog extends StatelessWidget {
  const DeleteTrackConfirmationDialog({
    super.key,
    required this.trackTitle,
  });

  final String trackTitle;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Track'),
      content: Text(
        'Are you sure you want to delete "$trackTitle"? This action cannot be undone from the app.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
