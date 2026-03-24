import 'package:flutter/material.dart';

class TrackManagementActionsSheet extends StatelessWidget {
  const TrackManagementActionsSheet({
    super.key,
    required this.onEditTap,
    required this.onVisibilityTap,
    required this.onDeleteTap,
  });

  final VoidCallback onEditTap;
  final VoidCallback onVisibilityTap;
  final VoidCallback onDeleteTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit metadata'),
            onTap: onEditTap,
          ),
          ListTile(
            leading: const Icon(Icons.visibility_outlined),
            title: const Text('Change visibility'),
            onTap: onVisibilityTap,
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Delete track'),
            onTap: onDeleteTap,
          ),
        ],
      ),
    );
  }
}
