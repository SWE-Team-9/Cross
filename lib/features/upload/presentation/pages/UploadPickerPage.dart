import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../bloc/uploadPickerCubit.dart';
import '../bloc/uploadPickerState.dart';
import '../widgets/SelectedAudioFileCard.dart';

class UploadPickerPage extends StatefulWidget {
  const UploadPickerPage({super.key});

  @override
  State<UploadPickerPage> createState() => _UploadPickerPageState();
}

class _UploadPickerPageState extends State<UploadPickerPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _genreController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _genreController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _genreController.dispose();
    super.dispose();
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

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Card(
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
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: state.isBusy ? null : cubit.pickAudioFile,
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
                  TextField(
                    controller: _titleController,
                    enabled: !state.isBusy,
                    decoration: const InputDecoration(
                      labelText: 'Track title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _genreController,
                    enabled: !state.isBusy,
                    decoration: const InputDecoration(
                      labelText: 'Genre (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: state.isBusy
                              ? null
                              : () {
                                  _titleController.clear();
                                  _genreController.clear();
                                  cubit.clearSelection();
                                },
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: state.isBusy
                              ? null
                              : () => cubit.uploadSelectedFile(
                                    title: _titleController.text,
                                    genre: _genreController.text,
                                  ),
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
                _UploadStatusCard(state: state),
              ],
            ),
          );
        },
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
  });

  final UploadPickerState state;

  @override
  Widget build(BuildContext context) {
    if (state.status == UploadPickerStatus.initial ||
        state.status == UploadPickerStatus.cancelled) {
      return const SizedBox.shrink();
    }

    String title;
    String subtitle;
    Widget? trailing;

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
        subtitle = 'Review the file, add a title, then upload.';
        trailing = const Icon(Icons.check_circle_outline);
        break;
      case UploadPickerStatus.uploading:
        title = 'Uploading';
        subtitle = 'Your file is being sent to the server.';
        trailing = const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
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
        break;
      case UploadPickerStatus.success:
        title = 'Upload complete';
        subtitle =
            'Track ID: ${state.uploadedTrackId ?? '-'}\nStatus: ${state.processingStatus ?? 'FINISHED'}';
        trailing = const Icon(Icons.check_circle, color: Colors.green);
        break;
      case UploadPickerStatus.failure:
        title = 'Upload failed';
        subtitle = state.errorMessage ?? 'Something went wrong.';
        trailing = const Icon(Icons.error_outline, color: Colors.red);
        break;
      case UploadPickerStatus.initial:
      case UploadPickerStatus.cancelled:
        return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
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
      ),
    );
  }
}
