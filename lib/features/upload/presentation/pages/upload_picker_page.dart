import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../domain/entities/track_management_visibility.dart';
import '../bloc/upload_picker_cubit.dart';
import '../bloc/upload_picker_state.dart';
import '../constants/track_genres.dart';
import '../widgets/selected_audio_file_card.dart';

class UploadPickerPage extends StatefulWidget {
  const UploadPickerPage({super.key});

  @override
  State<UploadPickerPage> createState() => _UploadPickerPageState();
}

class _UploadPickerPageState extends State<UploadPickerPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _tagsController;
  late final TextEditingController _descriptionController;
  String? _selectedGenre;

  TrackManagementVisibility _selectedVisibility =
      TrackManagementVisibility.privateTrack;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _tagsController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tagsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _resetForm(UploadPickerCubit cubit) {
    _titleController.clear();
    _tagsController.clear();
    _descriptionController.clear();

    setState(() {
      _selectedVisibility = TrackManagementVisibility.privateTrack;
      _selectedGenre = null;
    });

    cubit.clearSelection();
  }

  Future<void> _showPermissionSettingsDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Permission required'),
          content: const Text(
            'Audio file access is permanently denied. Please enable it from system settings to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;

    if (authState is! AuthAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Upload Track'),
        ),
        body: const _AccessInfoCard(
          title: 'Sign in required',
          message: 'Please sign in first to access audio uploads.',
          icon: Icons.lock_outline,
        ),
      );
    }

    final user = authState.user;

    if (!user.isArtist) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Upload Track'),
        ),
        body: _AccessInfoCard(
          title: 'Artist account required',
          message:
              'Upload is available for artists only. Your current account type is ${user.accountType}. Switch your account to ARTIST to continue.',
          icon: Icons.mic_off_outlined,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Track'),
      ),
      body: BlocConsumer<UploadPickerCubit, UploadPickerState>(
        listener: (context, state) {
          if (state.status == UploadPickerStatus.failure &&
              state.errorMessage != null) {
            if (state.failureType ==
                UploadPickerFailureType.permissionPermanentlyDenied) {
              _showPermissionSettingsDialog(context);
              return;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
              ),
            );
          }

          if (state.status == UploadPickerStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Upload completed successfully.'),
              ),
            );
          }
        },
        builder: (context, state) {
          final cubit = context.read<UploadPickerCubit>();
          final bool canStartNewUpload =
              !state.isBusy && !state.hasCreatedTrack;
          final bool canEditCurrentUpload =
              !state.isBusy && !state.hasCreatedTrack;
          final bool canClearCurrentUpload =
              !state.isBusy && state.hasSelection;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                _UserAccountCard(user: user),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: canStartNewUpload ? cubit.pickAudioFile : null,
                  child: Text(
                    state.status == UploadPickerStatus.picking
                        ? 'Selecting...'
                        : 'Select MP3 / WAV',
                  ),
                ),
                const SizedBox(height: 16),
                if (state.pickedAudioFile != null) ...[
                  SelectedAudioFileCard(
                    pickedAudioFile: state.pickedAudioFile!,
                  ),
                  const SizedBox(height: 16),
                  _UploadMetadataCard(
                    titleController: _titleController,
                    selectedGenre: _selectedGenre,
                    genreOptions: kTrackGenreNames,
                    onGenreChanged: (genre) {
                      setState(() {
                        _selectedGenre = genre;
                      });
                    },
                    tagsController: _tagsController,
                    descriptionController: _descriptionController,
                    isEnabled: canEditCurrentUpload,
                  ),
                  const SizedBox(height: 16),
                  _UploadVisibilityCard(
                    selectedVisibility: _selectedVisibility,
                    isEnabled: canEditCurrentUpload,
                    onChanged: (visibility) {
                      setState(() {
                        _selectedVisibility = visibility;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: canClearCurrentUpload
                              ? () => _resetForm(cubit)
                              : null,
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: canEditCurrentUpload
                              ? () {
                                  if (_selectedGenre == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please choose a genre before uploading.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  cubit.uploadSelectedFile(
                                    title: _titleController.text,
                                    genre: _selectedGenre,
                                    tagsInput: _tagsController.text,
                                    description: _descriptionController.text,
                                    visibility: _selectedVisibility,
                                  );
                                }
                              : null,
                          child: Text(
                            state.status == UploadPickerStatus.uploading
                                ? 'Uploading...'
                                : 'Upload Track',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                _UploadStatusCard(
                  state: state,
                  onCopyPrivateLink: state.privateShareToken == null
                      ? null
                      : () => _copyPrivateTrackLink(state.privateShareToken!),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _copyPrivateTrackLink(String secretToken) async {
    final String deepLink = 'soundclone://track/secret/$secretToken';

    await Clipboard.setData(ClipboardData(text: deepLink));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Private track link copied'),
      ),
    );
  }
}

class _UserAccountCard extends StatelessWidget {
  const _UserAccountCard({
    required this.user,
  });

  final dynamic user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              child: Icon(Icons.person),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName?.trim().isNotEmpty == true
                        ? user.displayName!
                        : user.email,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Account type: ${user.accountType}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Chip(
              label: Text(user.accountType),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadMetadataCard extends StatelessWidget {
  const _UploadMetadataCard({
    required this.titleController,
    required this.selectedGenre,
    required this.genreOptions,
    required this.onGenreChanged,
    required this.tagsController,
    required this.descriptionController,
    required this.isEnabled,
  });

  final TextEditingController titleController;
  final String? selectedGenre;
  final List<String> genreOptions;
  final ValueChanged<String?> onGenreChanged;
  final TextEditingController tagsController;
  final TextEditingController descriptionController;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Track metadata',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              enabled: isEnabled,
              decoration: const InputDecoration(
                labelText: 'Track title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(selectedGenre),
              initialValue: selectedGenre,
              hint: const Text('Select genre'),
              items: genreOptions
                  .map(
                    (genre) => DropdownMenuItem<String>(
                      value: genre,
                      child: Text(genre),
                    ),
                  )
                  .toList(),
              onChanged: isEnabled ? onGenreChanged : null,
              decoration: const InputDecoration(
                labelText: 'Genre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tagsController,
              enabled: isEnabled,
              decoration: const InputDecoration(
                labelText: 'Tags',
                hintText: 'lofi, chill, arabic',
                helperText: 'Comma separated. Up to 10 tags.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              enabled: isEnabled,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Description',
                helperText: 'Maximum 5000 characters.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadVisibilityCard extends StatelessWidget {
  const _UploadVisibilityCard({
    required this.selectedVisibility,
    required this.isEnabled,
    required this.onChanged,
  });

  final TrackManagementVisibility selectedVisibility;
  final bool isEnabled;
  final ValueChanged<TrackManagementVisibility> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Visibility',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose whether this track should stay private after upload or be published publicly.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: TrackManagementVisibility.values.map((visibility) {
                return ChoiceChip(
                  label: Text(visibility.displayLabel),
                  selected: selectedVisibility == visibility,
                  onSelected: isEnabled ? (_) => onChanged(visibility) : null,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessInfoCard extends StatelessWidget {
  const _AccessInfoCard({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 48),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UploadStatusCard extends StatelessWidget {
  const _UploadStatusCard({
    required this.state,
    required this.onCopyPrivateLink,
  });

  final UploadPickerState state;
  final VoidCallback? onCopyPrivateLink;

  @override
  Widget build(BuildContext context) {
    if (state.status == UploadPickerStatus.initial ||
        state.status == UploadPickerStatus.cancelled) {
      return const SizedBox.shrink();
    }

    String title;
    String subtitle;
    Widget? trailing;
    Widget? progressBar;
    String? progressLabel;

    switch (state.status) {
      case UploadPickerStatus.picking:
        title = 'Selecting file';
        subtitle = 'Please choose a supported MP3 or WAV file.';
        trailing = const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
        break;
      case UploadPickerStatus.ready:
        title = 'Ready to upload';
        subtitle =
            'Review the file, fill the metadata, choose visibility, then upload.';
        trailing = const Icon(Icons.check_circle_outline);
        break;
      case UploadPickerStatus.uploading:
        title = 'Uploading';
        subtitle = 'Your file is being sent to the server.';
        trailing = const Icon(Icons.cloud_upload_outlined);
        progressBar = LinearProgressIndicator(value: state.uploadProgress);
        if (state.uploadProgress != null) {
          progressLabel = '${(state.uploadProgress! * 100).round()}% uploaded';
        }
        break;
      case UploadPickerStatus.processing:
        title = 'Processing';
        subtitle =
            'Track ID: ${state.uploadedTrackId ?? '-'}\nStatus: ${state.processingStatus ?? 'PROCESSING'}';
        trailing = const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
        progressBar = const LinearProgressIndicator();
        break;
      case UploadPickerStatus.success:
        title = 'Upload complete';
        subtitle =
            'Track ID: ${state.uploadedTrackId ?? '-'}\nStatus: ${state.processingStatus ?? 'FINISHED'}';
        trailing = const Icon(Icons.check_circle, color: Colors.green);
        break;
      case UploadPickerStatus.failure:
        title = state.uploadedTrackId != null
            ? 'Upload completed with warning'
            : 'Upload failed';

        subtitle = state.errorMessage ?? 'Something went wrong.';

        if (state.uploadedTrackId != null) {
          subtitle =
              '$subtitle\n\nTrack ID: ${state.uploadedTrackId}\nStatus: ${state.processingStatus ?? '-'}';
        }

        trailing = const Icon(Icons.error_outline, color: Colors.red);
        break;
      case UploadPickerStatus.initial:
      case UploadPickerStatus.cancelled:
        return const SizedBox.shrink();
    }

    final visibility = state.uploadedVisibility;
    final bool hasPrivateLink =
        visibility == TrackManagementVisibility.privateTrack &&
            state.privateShareToken != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(subtitle),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                trailing,
              ],
            ),
            if (visibility != null) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: Icon(
                        visibility == TrackManagementVisibility.privateTrack
                            ? Icons.lock_outline
                            : Icons.public,
                        size: 18,
                      ),
                      label: Text(visibility.displayLabel),
                    ),
                    if (hasPrivateLink)
                      OutlinedButton.icon(
                        onPressed: onCopyPrivateLink,
                        icon: const Icon(Icons.link),
                        label: const Text('Copy private link'),
                      ),
                  ],
                ),
              ),
            ],
            if (progressBar != null) ...[
              const SizedBox(height: 16),
              progressBar,
            ],
            if (progressLabel != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(progressLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
