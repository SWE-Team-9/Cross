import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/ManagedTrack.dart';
import '../../domain/entities/TrackManagementVisibility.dart';
import '../bloc/trackManagementCubit.dart';
import '../bloc/trackManagementState.dart';
import '../widgets/DeleteTrackConfirmationDialog.dart';
import '../widgets/EditTrackMetadataForm.dart';
import '../widgets/TrackManagementActionsSheet.dart';
import '../widgets/TrackVisibilitySelector.dart';

class TrackManagementDemoPage extends StatefulWidget {
  const TrackManagementDemoPage({super.key});

  @override
  State<TrackManagementDemoPage> createState() =>
      _TrackManagementDemoPageState();
}

class _TrackManagementDemoPageState extends State<TrackManagementDemoPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _tagsController;

  final List<TrackGenreOption> _genreOptions = const [
    TrackGenreOption(id: 1, name: 'Ambient'),
    TrackGenreOption(id: 2, name: 'Electronic'),
    TrackGenreOption(id: 3, name: 'Hip-Hop'),
    TrackGenreOption(id: 4, name: 'Rock'),
    TrackGenreOption(id: 5, name: 'Pop'),
  ];

  ManagedTrack get _demoTrack => const ManagedTrack(
        id: 'demo-track-001',
        title: 'Midnight Echoes',
        description: 'Sprint 2 local demo track for edit/delete testing.',
        genreId: 1,
        genreName: 'Ambient',
        tags: <String>['demo', 'sprint2'],
        visibility: TrackManagementVisibility.publicTrack,
        durationInSeconds: 212,
      );

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _tagsController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrackManagementCubit>().initialize(_demoTrack);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TrackManagementCubit, TrackManagementState>(
      listener: (context, state) {
        final form = state.form;

        if (form != null) {
          final String joinedTags = form.tags.join(', ');

          if (_titleController.text != form.title) {
            _titleController.text = form.title;
          }

          if (_descriptionController.text != (form.description ?? '')) {
            _descriptionController.text = form.description ?? '';
          }

          if (_tagsController.text != joinedTags) {
            _tagsController.text = joinedTags;
          }
        }

        if (state.successMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(state.successMessage!)),
            );

          context.read<TrackManagementCubit>().clearFeedback();
        }

        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );

          context.read<TrackManagementCubit>().clearFeedback();
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Track Management Demo'),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: state.hasTrack
                    ? () => _showActionsSheet(context, state)
                    : null,
              ),
            ],
          ),
          body: !state.hasTrack
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _TrackPreviewCard(state: state),
                      const SizedBox(height: 16),
                      if (state.isDeleted)
                        _DeletedTrackCard(
                          onRestore: () {
                            context
                                .read<TrackManagementCubit>()
                                .initialize(_demoTrack);
                          },
                        )
                      else ...[
                        EditTrackMetadataForm(
                          state: state,
                          titleController: _titleController,
                          descriptionController: _descriptionController,
                          tagsController: _tagsController,
                          genreOptions: _genreOptions,
                          onTitleChanged:
                              context.read<TrackManagementCubit>().updateTitle,
                          onDescriptionChanged: context
                              .read<TrackManagementCubit>()
                              .updateDescription,
                          onTagsChanged: context
                              .read<TrackManagementCubit>()
                              .updateTagsFromInput,
                          onGenreChanged: (genre) {
                            context.read<TrackManagementCubit>().updateGenre(
                                  genreId: genre.id,
                                  genreName: genre.name,
                                );
                          },
                          onSave:
                              context.read<TrackManagementCubit>().saveMetadata,
                          onReset:
                              context.read<TrackManagementCubit>().resetForm,
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Visibility',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                TrackVisibilitySelector(
                                  value: state.form!.visibility,
                                  enabled: !state.isBusy,
                                  onChanged: context
                                      .read<TrackManagementCubit>()
                                      .updateVisibility,
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: state.canSaveVisibility
                                        ? context
                                            .read<TrackManagementCubit>()
                                            .saveVisibility
                                        : null,
                                    child: const Text('Save Visibility'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Danger Zone',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Deleting a track removes it from your listings and should be treated as gone from the app.',
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.tonal(
                                    onPressed: state.isBusy
                                        ? null
                                        : () => _confirmDelete(context, state),
                                    child: const Text('Delete Track'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }

  Future<void> _showActionsSheet(
    BuildContext context,
    TrackManagementState state,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (bottomSheetContext) {
        return TrackManagementActionsSheet(
          onEditTap: () => Navigator.of(bottomSheetContext).pop(),
          onVisibilityTap: () => Navigator.of(bottomSheetContext).pop(),
          onDeleteTap: () async {
            Navigator.of(bottomSheetContext).pop();
            await _confirmDelete(context, state);
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TrackManagementState state,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteTrackConfirmationDialog(
        trackTitle: state.currentTrack!.title,
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<TrackManagementCubit>().deleteTrack();
    }
  }
}

class _TrackPreviewCard extends StatelessWidget {
  const _TrackPreviewCard({
    required this.state,
  });

  final TrackManagementState state;

  @override
  Widget build(BuildContext context) {
    final track = state.currentTrack!;
    final tags = state.form?.sanitizedTags ?? track.tags;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Track',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(
              state.form?.normalizedTitle ?? track.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(state.form?.visibility.displayLabel ??
                      track.visibility.displayLabel),
                ),
                Chip(
                  label: Text(
                    state.form?.genreName ?? track.genreName ?? 'Unknown genre',
                  ),
                ),
                if (track.durationInSeconds != null)
                  Chip(
                    label: Text(
                      '${(track.durationInSeconds! ~/ 60).toString().padLeft(2, '0')}:${(track.durationInSeconds! % 60).toString().padLeft(2, '0')}',
                    ),
                  ),
              ],
            ),
            if ((state.form?.normalizedDescription ?? track.description) !=
                null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  state.form?.normalizedDescription ?? track.description!,
                ),
              ),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in tags) Chip(label: Text('#$tag')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DeletedTrackCard extends StatelessWidget {
  const _DeletedTrackCard({
    required this.onRestore,
  });

  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.delete_outline, size: 48),
            const SizedBox(height: 12),
            Text(
              'This demo track is marked as deleted.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Use restore to re-seed the local demo state and continue testing.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRestore,
              child: const Text('Restore Demo Track'),
            ),
          ],
        ),
      ),
    );
  }
}
