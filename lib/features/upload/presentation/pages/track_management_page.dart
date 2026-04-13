import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/managed_track.dart';
import '../../domain/entities/track_management_visibility.dart';
import '../bloc/track_management_cubit.dart';
import '../bloc/track_management_state.dart';
import '../constants/track_genres.dart';
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

  late final List<TrackGenreOption> _genreOptions = kTrackGenreNames
      .map((genreName) => TrackGenreOption(name: genreName))
      .toList(growable: false);

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
    const orangeColor = Color(0xFFFF7A00);
    
    final darkOrangeTheme = ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF0D0D0D),
      colorScheme: const ColorScheme.dark(
        primary: orangeColor,
        onPrimary: Colors.black,
        surface: Color(0xFF181818),
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: orangeColor,
        selectionColor: orangeColor.withOpacity(0.3),
        selectionHandleColor: orangeColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: orangeColor,
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: orangeColor,
          side: BorderSide(color: orangeColor.withOpacity(0.4), width: 1.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: orangeColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(color: Colors.grey.shade400),
        floatingLabelStyle: const TextStyle(color: orangeColor),
      ),
    );

    return Theme(
      data: darkOrangeTheme,
      child: BlocConsumer<TrackManagementCubit, TrackManagementState>(
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
                  SnackBar(
                    backgroundColor: const Color(0xFF1A1A1A),
                    content: Text(
                      state.successMessage!,
                      style: const TextStyle(color: Colors.white),
                    ),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: orangeColor.withOpacity(0.5)),
                    ),
                  ),
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
                  SnackBar(
                    backgroundColor: const Color(0xFF002A0A),
                    content: Text(
                      state.successMessage!,
                      style: const TextStyle(color: Colors.white),
                    ),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.greenAccent, width: 1),
                    ),
                  ),
                );
            }

            context.read<TrackManagementCubit>().clearFeedback();
            return;
          }

          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF2A0000),
                  content: Text(
                    state.errorMessage!,
                    style: const TextStyle(color: Colors.white),
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Colors.redAccent, width: 1),
                  ),
                ),
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
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(orangeColor),
                    ),
                  )
                : state.isDeleted
                    ? const _TrackDeletedView()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            _TrackPreviewCard(state: state),
                            const SizedBox(height: 24),
                            _SleekContainer(
                              child: EditTrackMetadataForm(
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
                            ),
                            const SizedBox(height: 24),
                            _SleekContainer(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Visibility',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  TrackVisibilitySelector(
                                    value: state.form!.visibility,
                                    enabled: !state.isBusy,
                                    onChanged: context
                                        .read<TrackManagementCubit>()
                                        .updateVisibility,
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(54),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: state.canSaveVisibility
                                        ? context
                                            .read<TrackManagementCubit>()
                                            .saveVisibility
                                        : null,
                                    child: const Text('Save Visibility', style: TextStyle(fontSize: 16)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            _SleekContainer(
                              borderColor: Colors.redAccent.withOpacity(0.3),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Danger Zone',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.redAccent,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Deleting a track removes it from your listings and should be treated as gone from the app.',
                                    style: TextStyle(color: Colors.grey.shade400, height: 1.4),
                                  ),
                                  const SizedBox(height: 24),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.redAccent,
                                      side: BorderSide(color: Colors.redAccent.withOpacity(0.5), width: 1.5),
                                      minimumSize: const Size.fromHeight(54),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: state.isBusy
                                        ? null
                                        : () => _confirmDelete(context, state),
                                    child: const Text('Delete Track', style: TextStyle(fontSize: 16)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
          );
        },
      ),
    );
  }

  Future<void> _showActionsSheet(
    BuildContext context,
    TrackManagementState state,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF181818),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return Theme(
           data: Theme.of(context),
           child: TrackManagementActionsSheet(
            onEditTap: () => Navigator.of(bottomSheetContext).pop(),
            onVisibilityTap: () => Navigator.of(bottomSheetContext).pop(),
            onDeleteTap: () async {
              Navigator.of(bottomSheetContext).pop();
              await _confirmDelete(context, state);
            },
          ),
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
      builder: (_) => Theme(
        data: Theme.of(context),
        child: DeleteTrackConfirmationDialog(
          trackTitle: state.currentTrack!.title,
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<TrackManagementCubit>().deleteTrack();
    }
  }
}

class _SleekContainer extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  
  const _SleekContainer({required this.child, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? Colors.white.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
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

    return _SleekContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.music_note, color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Current Track',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            state.form?.normalizedTitle ?? track.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      (state.form?.visibility ?? track.visibility) == TrackManagementVisibility.privateTrack
                          ? Icons.lock_outline
                          : Icons.public,
                      size: 14,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      state.form?.visibility.displayLabel ?? track.visibility.displayLabel,
                      style: TextStyle(color: Colors.grey.shade300, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  state.form?.genreName ?? track.genreName ?? 'Unknown genre',
                  style: TextStyle(color: Colors.grey.shade300, fontSize: 12),
                ),
              ),
              if (track.durationInSeconds != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                        Icon(Icons.timer_outlined, size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          '${(track.durationInSeconds! ~/ 60).toString().padLeft(2, '0')}:${(track.durationInSeconds! % 60).toString().padLeft(2, '0')}',
                          style: TextStyle(color: Colors.grey.shade300, fontSize: 12),
                        ),
                     ],
                  ),
                ),
            ],
          ),
          if ((state.form?.normalizedDescription ?? track.description) !=
              null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                state.form?.normalizedDescription ?? track.description!,
                style: TextStyle(color: Colors.grey.shade400, height: 1.4),
              ),
            ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in tags) 
                  Text(
                    '#$tag',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary.withOpacity(0.8), fontSize: 13),
                  ),
              ],
            ),
          ],
        ],
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
        child: _SleekContainer(
          borderColor: Colors.redAccent.withOpacity(0.3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete_outline, size: 56, color: Colors.redAccent),
              const SizedBox(height: 20),
              Text(
                'This track has been deleted.',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Close this page to return to your track list.',
                style: TextStyle(color: Colors.grey.shade400, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}