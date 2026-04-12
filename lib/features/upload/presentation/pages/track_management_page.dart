import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/managed_track.dart';
import '../../domain/entities/track_management_visibility.dart';
import '../bloc/track_management_cubit.dart';
import '../bloc/track_management_state.dart';
import '../models/track_management_result.dart';
import '../widgets/delete_track_confirmation_dialog.dart';
import '../widgets/edit_track_metadata_form.dart';
import '../widgets/track_management_actions_sheet.dart';
import '../widgets/track_visibility_selector.dart';

class TrackManagementPage extends StatefulWidget {
  const TrackManagementPage({
    super.key,
    required this.initialTrack,
    this.popOnSuccess = true,
  });

  final ManagedTrack initialTrack;
  final bool popOnSuccess;

  @override
  State<TrackManagementPage> createState() => _TrackManagementPageState();
}

class _TrackManagementPageState extends State<TrackManagementPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _tagsController;

  final List<TrackGenreOption> _genreOptions = const [
    TrackGenreOption(name: 'Ambient'),
    TrackGenreOption(name: 'Electronic'),
    TrackGenreOption(name: 'Hip-Hop'),
    TrackGenreOption(name: 'Rock'),
    TrackGenreOption(name: 'Pop'),
  ];

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _tagsController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrackManagementCubit>().initialize(widget.initialTrack);
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

        if (state.status == TrackManagementStatus.deleted &&
            state.currentTrack != null) {
          if (widget.popOnSuccess && context.mounted) {
            Navigator.of(context).pop(
              TrackDeletedResult(state.currentTrack!.id),
            );
            return;
          }

          if (state.successMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(state.successMessage!)),
              );
          }

          context.read<TrackManagementCubit>().clearFeedback();
          return;
        }

        if (state.status == TrackManagementStatus.success &&
            state.currentTrack != null) {
          if (widget.popOnSuccess && context.mounted) {
            Navigator.of(context).pop(
              TrackUpdatedResult(state.currentTrack!),
            );
            return;
          }

          if (state.successMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(state.successMessage!)),
              );
          }

          context.read<TrackManagementCubit>().clearFeedback();
          return;
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
            title: const Text('Track Management'),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: state.hasTrack && !state.isDeleted
                    ? () => _showActionsSheet(context, state)
                    : null,
              ),
            ],
          ),
          body: !state.hasTrack
              ? const Center(child: CircularProgressIndicator())
              : state.isDeleted
                  ? const _TrackDeletedView()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _TrackPreviewCard(state: state),
                          const SizedBox(height: 16),
                          EditTrackMetadataForm(
                            state: state,
                            titleController: _titleController,
                            descriptionController: _descriptionController,
                            tagsController: _tagsController,
                            genreOptions: _genreOptions,
                            onTitleChanged: context
                                .read<TrackManagementCubit>()
                                .updateTitle,
                            onDescriptionChanged: context
                                .read<TrackManagementCubit>()
                                .updateDescription,
                            onTagsChanged: context
                                .read<TrackManagementCubit>()
                                .updateTagsFromInput,
                            onGenreChanged: context
                                .read<TrackManagementCubit>()
                                .updateGenre,
                            onSave: context
                                .read<TrackManagementCubit>()
                                .saveMetadata,
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
                                          : () =>
                                              _confirmDelete(context, state),
                                      child: const Text('Delete Track'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
            Text(
              'Current Track',
              style: Theme.of(context).textTheme.titleMedium,
            ),
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
                  label: Text(
                    state.form?.visibility.displayLabel ??
                        track.visibility.displayLabel,
                  ),
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

class _TrackDeletedView extends StatelessWidget {
  const _TrackDeletedView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete_outline, size: 48),
            const SizedBox(height: 12),
            Text(
              'This track has been deleted.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Close this page to return to your track list.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
