import 'package:flutter/material.dart';

import '../../domain/entities/PickedAudioFile.dart';

class SelectedAudioFileCard extends StatelessWidget {
  const SelectedAudioFileCard({
    super.key,
    required this.pickedAudioFile,
  });

  final PickedAudioFile pickedAudioFile;

  @override
  Widget build(BuildContext context) {
    final String pathText = pickedAudioFile.path == null ||
            pickedAudioFile.path!.trim().isEmpty
        ? 'Unavailable on this platform'
        : pickedAudioFile.path!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${pickedAudioFile.name}'),
            const SizedBox(height: 8),
            Text('Extension: ${pickedAudioFile.extension.toUpperCase()}'),
            const SizedBox(height: 8),
            Text('Size: ${pickedAudioFile.formattedSize}'),
            const SizedBox(height: 8),
            Text('Path: $pathText'),
          ],
        ),
      ),
    );
  }
}