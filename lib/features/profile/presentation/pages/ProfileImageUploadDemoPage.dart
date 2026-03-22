import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injector.dart';
import '../../domain/entities/ProfileImageUploadResult.dart';
import '../bloc/profileImageUploadCubit.dart';
import '../bloc/profileImageUploadState.dart';
import '../widgets/ProfileImagePickerSheet.dart';
import '../widgets/ProfileImageUploadProgress.dart';

class ProfileImageUploadDemoPage extends StatelessWidget {
  const ProfileImageUploadDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileImageUploadCubit>(
      create: (_) => getIt<ProfileImageUploadCubit>(),
      child: const _ProfileImageUploadDemoView(),
    );
  }
}

class _ProfileImageUploadDemoView extends StatelessWidget {
  const _ProfileImageUploadDemoView();

  bool get _supportsCameraCapture {
    if (kIsWeb) {
      return false;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileImageUploadCubit, ProfileImageUploadState>(
      listener: (context, state) {
        if (state.status == ProfileImageUploadStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }

        if (state.status == ProfileImageUploadStatus.success &&
            state.lastUploadResult != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${state.lastUploadResult!.type.displayName} image uploaded successfully.',
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<ProfileImageUploadCubit>();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile Image Upload Demo'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CoverPreview(
                  state: state,
                  onChangeTap: () => _showPickerSheet(
                    context,
                    title: 'Change Cover Image',
                    showCameraOption: _supportsCameraCapture,
                    onGalleryTap: () {
                      Navigator.of(context).pop();
                      cubit.pickImage(
                        type: ProfileImageType.cover,
                        source: ImageSource.gallery,
                      );
                    },
                    onCameraTap: () {
                      Navigator.of(context).pop();
                      cubit.pickImage(
                        type: ProfileImageType.cover,
                        source: ImageSource.camera,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _AvatarPreview(
                  state: state,
                  onChangeTap: () => _showPickerSheet(
                    context,
                    title: 'Change Avatar',
                    showCameraOption: _supportsCameraCapture,
                    onGalleryTap: () {
                      Navigator.of(context).pop();
                      cubit.pickImage(
                        type: ProfileImageType.avatar,
                        source: ImageSource.gallery,
                      );
                    },
                    onCameraTap: () {
                      Navigator.of(context).pop();
                      cubit.pickImage(
                        type: ProfileImageType.avatar,
                        source: ImageSource.camera,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                if (state.hasPreparedImage) ...[
                  Text(
                    'Prepared image',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _PreparedImageDetails(state: state),
                  const SizedBox(height: 16),
                  ProfileImageUploadProgress(state: state),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              state.status == ProfileImageUploadStatus.uploading
                                  ? null
                                  : cubit.uploadSelectedImage,
                          child: Text(
                            'Upload ${state.activeImageType?.displayName ?? 'Image'}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              state.status == ProfileImageUploadStatus.uploading
                                  ? null
                                  : cubit.clearSelection,
                          child: const Text('Clear'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPickerSheet(
    BuildContext context, {
    required String title,
    required bool showCameraOption,
    required VoidCallback onGalleryTap,
    required VoidCallback onCameraTap,
  }) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) {
        return ProfileImagePickerSheet(
          title: title,
          showCameraOption: showCameraOption,
          onGalleryTap: onGalleryTap,
          onCameraTap: onCameraTap,
        );
      },
    );
  }
}

class _CoverPreview extends StatelessWidget {
  const _CoverPreview({
    required this.state,
    required this.onChangeTap,
  });

  final ProfileImageUploadState state;
  final VoidCallback onChangeTap;

  @override
  Widget build(BuildContext context) {
    final bool showPreparedCover =
        state.activeImageType == ProfileImageType.cover &&
            state.previewBytes != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cover',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 180,
            width: double.infinity,
            child: _buildImage(
              memoryBytes: showPreparedCover
                  ? state.previewBytes
                  : state.currentCoverBytes,
              networkUrl: showPreparedCover ? null : state.currentCoverUrl,
              icon: Icons.image_outlined,
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onChangeTap,
          child: const Text('Change Cover'),
        ),
      ],
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({
    required this.state,
    required this.onChangeTap,
  });

  final ProfileImageUploadState state;
  final VoidCallback onChangeTap;

  @override
  Widget build(BuildContext context) {
    final bool showPreparedAvatar =
        state.activeImageType == ProfileImageType.avatar &&
            state.previewBytes != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Avatar',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            CircleAvatar(
              radius: 44,
              backgroundImage: _buildAvatarImageProvider(
                memoryBytes: showPreparedAvatar
                    ? state.previewBytes
                    : state.currentAvatarBytes,
                networkUrl: showPreparedAvatar ? null : state.currentAvatarUrl,
              ),
              child: !showPreparedAvatar &&
                      state.currentAvatarUrl == null &&
                      state.currentAvatarBytes == null
                  ? const Icon(Icons.person_outline, size: 36)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton(
                onPressed: onChangeTap,
                child: const Text('Change Avatar'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  ImageProvider<Object>? _buildAvatarImageProvider({
    Uint8List? memoryBytes,
    String? networkUrl,
  }) {
    if (memoryBytes != null) {
      return MemoryImage(memoryBytes);
    }

    if (networkUrl != null && networkUrl.trim().isNotEmpty) {
      return NetworkImage(networkUrl);
    }

    return null;
  }
}

class _PreparedImageDetails extends StatelessWidget {
  const _PreparedImageDetails({
    required this.state,
  });

  final ProfileImageUploadState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                state.previewBytes!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Type',
              value: state.activeImageType?.displayName ?? '-',
            ),
            _InfoRow(
              label: 'File name',
              value: state.selectedFileName ?? '-',
            ),
            _InfoRow(
              label: 'MIME type',
              value: state.selectedMimeType ?? '-',
            ),
            _InfoRow(
              label: 'Size',
              value: _formatBytes(state.selectedFileSizeInBytes ?? 0),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildImage({
  Uint8List? memoryBytes,
  String? networkUrl,
  required IconData icon,
}) {
  if (memoryBytes != null) {
    return Image.memory(
      memoryBytes,
      fit: BoxFit.cover,
    );
  }

  if (networkUrl != null && networkUrl.trim().isNotEmpty) {
    return Image.network(
      networkUrl,
      fit: BoxFit.cover,
    );
  }

  return ColoredBox(
    color: const Color(0xFFF1F3F5),
    child: Center(
      child: Icon(
        icon,
        size: 42,
      ),
    ),
  );
}
