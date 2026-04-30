import 'package:flutter/material.dart';

import '../../domain/entities/track_genre.dart';
import '../bloc/track_management_state.dart';

class TrackGenreOption {
  const TrackGenreOption({
    required this.name,
  });

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
    required this.onReleaseDateChanged,
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
  final ValueChanged<DateTime?> onReleaseDateChanged;
  final ValueChanged<String> onGenreChanged;
  final VoidCallback onSave;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final form = state.form;

    if (form == null) {
      return const SizedBox.shrink();
    }

    final String? normalizedGenreName = normalizeTrackGenreName(form.genreName);
    final bool hasSelectedGenre = genreOptions.any(
      (genre) =>
          genre.name == form.genreName || genre.name == normalizedGenreName,
    );
    final String? selectedGenreName = hasSelectedGenre
        ? genreOptions
            .firstWhere(
              (genre) =>
                  genre.name == form.genreName ||
                  genre.name == normalizedGenreName,
            )
            .name
        : null;

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
            DropdownButtonFormField<String>(
              key: ValueKey(selectedGenreName),
              initialValue: selectedGenreName,
              decoration: InputDecoration(
                labelText: 'Genre',
                errorText: form.genreValidationError,
                border: const OutlineInputBorder(),
              ),
              items: genreOptions.map((genre) {
                return DropdownMenuItem<String>(
                  value: genre.name,
                  child: Text(genre.name),
                );
              }).toList(),
              onChanged: (!state.isBusy && !state.isDeleted)
                  ? (genreName) {
                      if (genreName == null || genreName.trim().isEmpty) {
                        return;
                      }

                      onGenreChanged(genreName);
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
                helperText: 'Up to 10 tags. Each tag should be under 30 chars.',
                errorText: form.tagsValidationError,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: (state.isBusy || state.isDeleted)
                  ? null
                  : () async {
                      final DateTime now = DateTime.now();
                      final DateTime initialDate = form.releaseDate ?? now;
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: initialDate,
                        firstDate: DateTime(1900),
                        lastDate: DateTime(now.year + 10),
                      );
                      onReleaseDateChanged(pickedDate);
                    },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Release date',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  form.releaseDate == null
                      ? 'Pick date (optional)'
                      : '${form.releaseDate!.year.toString().padLeft(4, '0')}-${form.releaseDate!.month.toString().padLeft(2, '0')}-${form.releaseDate!.day.toString().padLeft(2, '0')}',
                ),
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
