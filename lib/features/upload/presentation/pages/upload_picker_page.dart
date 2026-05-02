// coverage:ignore-file
import 'dart:io' show File;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_state.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../playback/presentation/bloc/player_cubit.dart';
import '../../domain/entities/picked_image_file.dart';
import '../../domain/entities/track_management_visibility.dart';
import '../bloc/upload_picker_cubit.dart';
import '../bloc/upload_picker_state.dart';
import '../constants/track_genres.dart';
import '../widgets/selected_audio_file_card.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_cubit.dart';
import 'package:go_router/go_router.dart';

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
  PickedImageFile? _selectedCoverArt;
  DateTime? _selectedReleaseDate;

  TrackManagementVisibility _selectedVisibility =
      TrackManagementVisibility.privateTrack;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _tagsController = TextEditingController();
    _descriptionController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _setMiniPlayerVisible(false);
    });
  }

  @override
  void dispose() {
    _setMiniPlayerVisible(true);
    _titleController.dispose();
    _tagsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _setMiniPlayerVisible(bool visible) {
    try {
      final playerCubit = context.read<PlayerCubit>();
      if (visible) {
        playerCubit.showMiniPlayer();
      } else {
        playerCubit.hideMiniPlayer();
      }
    } catch (_) {}
  }

  void _resetForm(UploadPickerCubit cubit) {
    _titleController.clear();
    _tagsController.clear();
    _descriptionController.clear();

    setState(() {
      _selectedVisibility = TrackManagementVisibility.privateTrack;
      _selectedGenre = null;
      _selectedCoverArt = null;
      _selectedReleaseDate = null;
    });

    cubit.clearSelection();
  }

  Future<void> _showPermissionSettingsDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Permission required',
              style: TextStyle(color: Colors.white)),
          content: const Text(
            'Audio file access is permanently denied. Please enable it from system settings to continue.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A00),
                foregroundColor: Colors.black,
              ),
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

  Future<void> _pickCoverArt() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      );

      if (result == null || result.files.isEmpty || !mounted) return;

      final file = result.files.single;
      final path = file.path;
      if (path == null || path.trim().isEmpty) {
        _showUploadMessage('Selected cover image path is unavailable.');
        return;
      }

      setState(() {
        _selectedCoverArt = PickedImageFile(
          name: file.name,
          extension: (file.extension ?? file.name.split('.').last)
              .trim()
              .toLowerCase(),
          sizeInBytes: file.size,
          path: path,
        );
      });
    } catch (_) {
      if (!mounted) return;
      _showUploadMessage('Unable to select cover image. Please try again.');
    }
  }

  void _showUploadMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1A1A1A),
          content: Text(message, style: const TextStyle(color: Colors.white)),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
  bool _isUploadLimitFailure(String message) {
    final normalized = message.toLowerCase();

    return normalized.contains('upload limit reached') ||
        normalized.contains('upgrade to pro') ||
        normalized.contains('subscription is not active') ||
        normalized.contains('billing status');
  }
  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;

    const orangeColor = Color(0xFFFF7A00);

    final darkOrangeTheme = ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF0D0D0D),
      colorScheme: const ColorScheme.dark(
        primary: orangeColor,
        onPrimary: Colors.black,
        secondary: orangeColor,
        secondaryContainer: Color(0x33FF7A00),
        onSecondaryContainer: orangeColor,
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
        selectionColor: orangeColor.withValues(alpha: 0.3),
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
          side:
              BorderSide(color: orangeColor.withValues(alpha: 0.4), width: 1.5),
        ),
      ),
    );

    Widget pageContent;

    if (authState is! AuthAuthenticated) {
      pageContent = Scaffold(
        appBar: AppBar(
          title: const Text('Upload Track'),
        ),
        body: const _AccessInfoCard(
          title: 'Sign in required',
          message: 'Please sign in first to access audio uploads.',
          icon: Icons.lock_outline,
        ),
      );
    } else {
      final user = authState.user;

      if (!user.isArtist) {
        pageContent = Scaffold(
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
      } else {
        pageContent = Scaffold(
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

                final errorMessage = state.errorMessage!;
                final isUploadLimitFailure = _isUploadLimitFailure(errorMessage);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF2A0000),
                    content: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.white),
                    ),
                    behavior: SnackBarBehavior.floating,
                    action: isUploadLimitFailure
                        ? SnackBarAction(
                            label: 'Upgrade',
                            textColor: orangeColor,
                            onPressed: () => context.go('/upgrade'),
                          )
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.redAccent, width: 1),
                    ),
                  ),
                );
              }              if (state.status == UploadPickerStatus.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF002A0A),
                    content: const Text(
                      'Upload completed successfully.',
                      style: TextStyle(color: Colors.white),
                    ),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side:
                          const BorderSide(color: Colors.greenAccent, width: 1),
                    ),
                  ),
                );
                context.read<SubscriptionCubit>().refreshAfterPayment();
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _UserAccountCard(user: user),
                    const SizedBox(height: 16),
                    const _UploadQuotaCard(),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: canStartNewUpload ? cubit.pickAudioFile : null,
                      icon: Icon(
                        state.status == UploadPickerStatus.picking
                            ? Icons.hourglass_top
                            : Icons.audio_file_outlined,
                      ),
                      label: Text(
                        state.status == UploadPickerStatus.picking
                            ? 'Selecting...'
                            : 'Select audio file',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (state.pickedAudioFile != null) ...[
                      SelectedAudioFileCard(
                        pickedAudioFile: state.pickedAudioFile!,
                      ),
                      const SizedBox(height: 16),
                      _UploadMetadataCard(
                        titleController: _titleController,
                        selectedGenre: _selectedGenre,
                        selectedCoverArt: _selectedCoverArt,
                        selectedReleaseDate: _selectedReleaseDate,
                        onCoverArtChanged: (coverArt) {
                          setState(() {
                            _selectedCoverArt = coverArt;
                          });
                        },
                        onPickCoverArt: _pickCoverArt,
                        onReleaseDateChanged: (date) {
                          setState(() {
                            _selectedReleaseDate = date;
                          });
                        },
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
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: canClearCurrentUpload
                                  ? () => _resetForm(cubit)
                                  : null,
                              child: const Text('Clear'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: canEditCurrentUpload
                                  ? () {
                                      if (_selectedGenre == null) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            backgroundColor:
                                                const Color(0xFF1A1A1A),
                                            content: const Text(
                                              'Please choose a genre before uploading.',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              side: BorderSide(
                                                  color: orangeColor.withValues(
                                                      alpha: 0.5)),
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      cubit.uploadSelectedFile(
                                        title: _titleController.text,
                                        coverArt: _selectedCoverArt,
                                        genre: _selectedGenre,
                                        tagsInput: _tagsController.text,
                                        description:
                                            _descriptionController.text,
                                        releaseDate: _selectedReleaseDate,
                                        visibility: _selectedVisibility,
                                      );
                                    }
                                  : null,
                              child: Text(
                                state.status == UploadPickerStatus.uploading
                                    ? 'Uploading...'
                                    : 'Upload Track',
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    _UploadStatusCard(
                      state: state,
                      onCopyPrivateLink: state.privateShareToken == null
                          ? null
                          : () =>
                              _copyPrivateTrackLink(state.privateShareToken!),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
        );
      }
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          context.read<PlayerCubit>().showMiniPlayer();
        }
      },
      child: Theme(
        data: darkOrangeTheme,
        child: pageContent,
      ),
    );
  }

  Future<void> _copyPrivateTrackLink(String secretToken) async {
    final String deepLink = 'soundclone://track/secret/$secretToken';

    await Clipboard.setData(ClipboardData(text: deepLink));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1A1A1A),
        content: const Text('Private track link copied',
            style: TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}

class _SleekContainer extends StatelessWidget {
  final Widget child;
  const _SleekContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(20),
      child: child,
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
    return _SleekContainer(
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
            child: Icon(
              Icons.person,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName?.trim().isNotEmpty == true
                      ? user.displayName!
                      : user.email,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Account type: ${user.accountType}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade400,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.3)),
            ),
            child: Text(
              user.accountType,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadQuotaCard extends StatelessWidget {
  const _UploadQuotaCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubscriptionCubit, SubscriptionState>(
      builder: (context, state) {
        if (state.isInitial || state.isLoading) {
          return const _SleekContainer(
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Loading upload quota...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          );
        }

        final subscription = state.subscription;
        final isUnlimited = subscription.isUnlimited;
        final remainingUploads = subscription.remainingUploads;
        final hasReachedLimit = !isUnlimited && remainingUploads <= 0;
        final quotaText = isUnlimited
            ? 'Unlimited uploads'
            : '${subscription.displayRemainingUploads} uploads remaining / ${subscription.displayUploadLimit}';

        return _SleekContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    hasReachedLimit
                        ? Icons.lock_outline
                        : Icons.cloud_upload_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Upload quota',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      subscription.isPremium ? 'Premium' : 'Free',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                quotaText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hasReachedLimit
                    ? 'You reached your current upload limit. Upgrade to continue uploading tracks.'
                    : subscription.isPremium
                        ? 'Your premium plan gives you more room to publish music.'
                        : 'Free artists have a limited number of uploads.',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  height: 1.4,
                ),
              ),
              if (hasReachedLimit) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/upgrade'),
                    icon: const Icon(Icons.workspace_premium_rounded),
                    label: const Text('Upgrade to upload more'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
class _UploadMetadataCard extends StatelessWidget {
  const _UploadMetadataCard({
    required this.titleController,
    required this.selectedGenre,
    required this.selectedCoverArt,
    required this.selectedReleaseDate,
    required this.onCoverArtChanged,
    required this.onPickCoverArt,
    required this.onReleaseDateChanged,
    required this.genreOptions,
    required this.onGenreChanged,
    required this.tagsController,
    required this.descriptionController,
    required this.isEnabled,
  });

  final TextEditingController titleController;
  final String? selectedGenre;
  final PickedImageFile? selectedCoverArt;
  final DateTime? selectedReleaseDate;
  final ValueChanged<PickedImageFile?> onCoverArtChanged;
  final VoidCallback onPickCoverArt;
  final ValueChanged<DateTime?> onReleaseDateChanged;
  final List<String> genreOptions;
  final ValueChanged<String?> onGenreChanged;
  final TextEditingController tagsController;
  final TextEditingController descriptionController;
  final bool isEnabled;

  InputDecoration _buildInputDecoration(BuildContext context, String label,
      {String? hint, String? helper}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.3),
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
        borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(color: Colors.grey.shade400),
      floatingLabelStyle:
          TextStyle(color: Theme.of(context).colorScheme.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SleekContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Track Metadata',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          _CoverArtPicker(
            coverArt: selectedCoverArt,
            enabled: isEnabled,
            onPick: onPickCoverArt,
            onRemove: () => onCoverArtChanged(null),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: titleController,
            enabled: isEnabled,
            style: const TextStyle(color: Colors.white),
            decoration: _buildInputDecoration(context, 'Track title'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: ValueKey(selectedGenre),
            initialValue: selectedGenre,
            hint: Text('Select genre',
                style: TextStyle(color: Colors.grey.shade500)),
            dropdownColor: const Color(0xFF1E1E1E),
            style: const TextStyle(color: Colors.white),
            items: genreOptions
                .map(
                  (genre) => DropdownMenuItem<String>(
                    value: genre,
                    child: Text(genre),
                  ),
                )
                .toList(),
            onChanged: isEnabled ? onGenreChanged : null,
            decoration: _buildInputDecoration(context, 'Genre'),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: !isEnabled
                ? null
                : () async {
                    final now = DateTime.now();
                    final initialDate = selectedReleaseDate ?? now;
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: initialDate,
                      firstDate: DateTime(1900),
                      lastDate: DateTime(now.year + 10),
                    );
                    onReleaseDateChanged(selected);
                  },
            child: InputDecorator(
              decoration: _buildInputDecoration(
                context,
                'Release date',
                helper: 'Optional',
              ),
              child: Text(
                selectedReleaseDate == null
                    ? 'Pick date'
                    : '${selectedReleaseDate!.year.toString().padLeft(4, '0')}-${selectedReleaseDate!.month.toString().padLeft(2, '0')}-${selectedReleaseDate!.day.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: selectedReleaseDate == null
                      ? Colors.grey.shade500
                      : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: tagsController,
            enabled: isEnabled,
            style: const TextStyle(color: Colors.white),
            decoration: _buildInputDecoration(
              context,
              'Tags',
              hint: 'lofi, chill, arabic',
              helper: 'Comma separated. Up to 10 tags, 30 chars each.',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: descriptionController,
            enabled: isEnabled,
            minLines: 4,
            maxLines: 6,
            style: const TextStyle(color: Colors.white),
            decoration: _buildInputDecoration(
              context,
              'Description',
              helper: 'Maximum 5000 characters.',
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverArtPicker extends StatelessWidget {
  const _CoverArtPicker({
    required this.coverArt,
    required this.enabled,
    required this.onPick,
    required this.onRemove,
  });

  final PickedImageFile? coverArt;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final selected = coverArt;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 88,
          height: 88,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: selected == null
              ? const Icon(Icons.image_outlined, color: Colors.white54)
              : Image.file(
                  File(selected.path),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image_outlined),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selected?.name ?? 'Track cover',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                selected == null
                    ? 'JPEG, PNG, or WebP.'
                    : selected.formattedSize,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: enabled ? onPick : null,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(selected == null ? 'Choose cover' : 'Replace'),
                  ),
                  if (selected != null)
                    IconButton(
                      tooltip: 'Remove cover',
                      onPressed: enabled ? onRemove : null,
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
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
    return _SleekContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visibility',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose whether this track should stay private after upload or be published publicly.',
            style: TextStyle(color: Colors.grey.shade400, height: 1.4),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            children: TrackManagementVisibility.values.map((visibility) {
              final isSelected = selectedVisibility == visibility;
              return ChoiceChip(
                label: Text(visibility.displayLabel),
                selected: isSelected,
                onSelected: isEnabled ? (_) => onChanged(visibility) : null,
                selectedColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.15),
                backgroundColor: Colors.black.withValues(alpha: 0.3),
                labelStyle: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade300,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isSelected
                      ? BorderSide(color: Theme.of(context).colorScheme.primary)
                      : BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              );
            }).toList(),
          ),
        ],
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
        padding: const EdgeInsets.all(24),
        child: _SleekContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 56,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.8)),
              const SizedBox(height: 20),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade400,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
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
  bool _isUploadLimitMessage(String message) {
    final normalized = message.toLowerCase();

    return normalized.contains('upload limit reached') ||
        normalized.contains('upgrade to pro') ||
        normalized.contains('subscription is not active') ||
        normalized.contains('billing status');
  }
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
        subtitle =
            'Please choose a supported audio file (MP3, WAV, FLAC, AIFF, M4A, AAC, OGG).';
        trailing = const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        );
        break;
      case UploadPickerStatus.ready:
        title = 'Ready to upload';
        subtitle =
            'Review the file, fill the metadata, choose visibility, then upload.';
        trailing = Icon(Icons.check_circle_outline,
            color: Theme.of(context).colorScheme.primary);
        break;
      case UploadPickerStatus.uploading:
        title = 'Uploading...';
        subtitle = 'Your file is being sent to the server.';
        trailing = Icon(Icons.cloud_upload_outlined,
            color: Theme.of(context).colorScheme.primary);
        progressBar = LinearProgressIndicator(
          value: state.uploadProgress,
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(4),
          minHeight: 6,
        );
        if (state.uploadProgress != null) {
          progressLabel = '${(state.uploadProgress! * 100).round()}% uploaded';
        }
        break;
      case UploadPickerStatus.processing:
        title = 'Processing';
        subtitle =
            'Track ID: ${state.uploadedTrackId ?? '-'}\nStatus: ${state.processingStatus ?? 'PROCESSING'}';
        trailing = const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        );
        progressBar = LinearProgressIndicator(
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(4),
          minHeight: 6,
        );
        break;
      case UploadPickerStatus.success:
        title = 'Upload complete';
        subtitle =
            'Track ID: ${state.uploadedTrackId ?? '-'}\nStatus: ${state.processingStatus ?? 'FINISHED'}';
        trailing = const Icon(Icons.check_circle, color: Colors.greenAccent);
        break;
      case UploadPickerStatus.failure:
        final errorMessage = state.errorMessage ?? 'Something went wrong.';
        final isLimitFailure = _isUploadLimitMessage(errorMessage);

        title = state.uploadedTrackId != null
            ? 'Upload completed with warning'
            : isLimitFailure
                ? 'Upload limit reached'
                : 'Upload failed';

        subtitle = errorMessage;

        if (state.uploadedTrackId != null) {
          subtitle =
              '$subtitle\n\nTrack ID: ${state.uploadedTrackId}\nStatus: ${state.processingStatus ?? '-'}';
        }

        trailing = Icon(
          isLimitFailure
              ? Icons.workspace_premium_outlined
              : Icons.error_outline,
          color: isLimitFailure
              ? Theme.of(context).colorScheme.primary
              : Colors.redAccent,
        );
        break;      case UploadPickerStatus.initial:
      case UploadPickerStatus.cancelled:
        return const SizedBox.shrink();
    }

    final visibility = state.uploadedVisibility;
    final bool hasPrivateLink =
        visibility == TrackManagementVisibility.privateTrack &&
            state.privateShareToken != null;

    return _SleekContainer(
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style:
                          TextStyle(color: Colors.grey.shade400, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              trailing,
            ],
          ),
          if (visibility != null) ...[
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          visibility == TrackManagementVisibility.privateTrack
                              ? Icons.lock_outline
                              : Icons.public,
                          size: 16,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          visibility.displayLabel,
                          style: TextStyle(
                              color: Colors.grey.shade300, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (hasPrivateLink)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 0),
                      ),
                      onPressed: onCopyPrivateLink,
                      icon: const Icon(Icons.link, size: 18),
                      label: const Text('Copy private link'),
                    ),
                ],
              ),
            ),
          ],
          if (progressBar != null) ...[
            const SizedBox(height: 20),
            progressBar,
          ],
          if (progressLabel != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                progressLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
