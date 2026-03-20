import 'package:flutter/material.dart';

import '../bloc/profileImageUploadState.dart';

class ProfileImageUploadProgress extends StatelessWidget {
  const ProfileImageUploadProgress({
    super.key,
    required this.state,
  });

  final ProfileImageUploadState state;

  @override
  Widget build(BuildContext context) {
    if (state.status != ProfileImageUploadStatus.uploading) {
      return const SizedBox.shrink();
    }

    final bool isDeterminate = state.uploadProgress > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Uploading image...',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: isDeterminate ? state.uploadProgress : null,
        ),
        const SizedBox(height: 8),
        Text(
          isDeterminate
              ? '${(state.uploadProgress * 100).toStringAsFixed(0)}%'
              : 'Preparing upload...',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
