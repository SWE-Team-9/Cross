import 'package:flutter/material.dart';

import '../bloc/track_management_state.dart';

class TrackGenreOption {
  const TrackGenreOption({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;
}

class EditTrackMetadataForm extends StatelessWidget {
  const EditTrackMetadataForm({
    super.key,
    required this.state,
    required this.titleController,
    required this.descriptionController,
    required this.tagsController,
    required this.genreOptions,
    required this.onTitleChanged,
    required this.onDescriptionChanged,
    required this.onTagsChanged,
    required this.onGenreChanged,
    required this.onSave,
    required this.onReset,
  });

  final TrackManagementState state;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController tagsController;
  final List<TrackGenreOption> genreOptions;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<String> onTagsChanged;
  final ValueChanged<TrackGenreOption> onGenreChanged;
  final VoidCallback onSave;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final form = state.form;

    if (form == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit metadata',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              enabled: !state.isBusy && !state.isDeleted,
              onChanged: onTitleChanged,
              decoration: InputDecoration(
                labelText: 'Title',
                errorText: form.titleValidationError,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              enabled: !state.isBusy && !state.isDeleted,
              minLines: 3,
              maxLines: 5,
              onChanged: onDescriptionChanged,
              decoration: InputDecoration(
                labelText: 'Description',
                errorText: form.descriptionValidationError,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              key: ValueKey(form.genreId),
              initialValue: form.genreId,
              decoration: InputDecoration(
                labelText: 'Genre',
                errorText: form.genreValidationError,
                border: const OutlineInputBorder(),
              ),
              items: genreOptions.map((genre) {
                return DropdownMenuItem<int>(
                  value: genre.id,
                  child: Text(genre.name),
                );
              }).toList(),
              onChanged: (!state.isBusy && !state.isDeleted)
                  ? (genreId) {
                      if (genreId == null) {
                        return;
                      }

                      final selectedGenre = genreOptions.firstWhere(
                        (genre) => genre.id == genreId,
                      );

                      onGenreChanged(selectedGenre);
                    }
                  : null,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tagsController,
              enabled: !state.isBusy && !state.isDeleted,
              onChanged: onTagsChanged,
              decoration: InputDecoration(
                labelText: 'Tags',
                hintText: 'comma, separated, tags',
                helperText: 'Up to 10 tags. Each tag should be under 50 chars.',
                errorText: form.tagsValidationError,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: state.canSaveMetadata ? onSave : null,
                    child: const Text('Save Details'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        (!state.isBusy && !state.isDeleted) ? onReset : null,
                    child: const Text('Reset'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
