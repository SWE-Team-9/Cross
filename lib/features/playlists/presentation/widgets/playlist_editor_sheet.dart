import 'dart:io' show File;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:soundcloud_clone/core/utils/platform_url_utils.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_genre.dart';

class PlaylistEditorResult {
  final String title;
  final String description;
  final PlaylistVisibility visibility;
  final String? genre;
  final String? coverImagePath;

  const PlaylistEditorResult({
    required this.title,
    required this.description,
    required this.visibility,
    this.genre,
    this.coverImagePath,
  });
}

class PlaylistEditorSheet extends StatefulWidget {
  final String title;
  final String submitLabel;
  final String initialTitle;
  final String initialDescription;
  final PlaylistVisibility initialVisibility;
  final String? initialGenre;
  final String? initialCoverImageUrl;

  const PlaylistEditorSheet({
    super.key,
    required this.title,
    required this.submitLabel,
    this.initialTitle = '',
    this.initialDescription = '',
    this.initialVisibility = PlaylistVisibility.publicPlaylist,
    this.initialGenre,
    this.initialCoverImageUrl,
  });

  static Future<PlaylistEditorResult?> show(
    BuildContext context, {
    required String title,
    required String submitLabel,
    String initialTitle = '',
    String initialDescription = '',
    PlaylistVisibility initialVisibility = PlaylistVisibility.publicPlaylist,
    String? initialGenre,
    String? initialCoverImageUrl,
  }) {
    return showModalBottomSheet<PlaylistEditorResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return PlaylistEditorSheet(
          title: title,
          submitLabel: submitLabel,
          initialTitle: initialTitle,
          initialDescription: initialDescription,
          initialVisibility: initialVisibility,
          initialGenre: initialGenre,
          initialCoverImageUrl: initialCoverImageUrl,
        );
      },
    );
  }

  @override
  State<PlaylistEditorSheet> createState() => _PlaylistEditorSheetState();
}

class _PlaylistEditorSheetState extends State<PlaylistEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late PlaylistVisibility _visibility;
  late String _genre;
  String? _coverImagePath;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _descriptionController =
        TextEditingController(text: widget.initialDescription);
    _visibility = widget.initialVisibility;
    final normalizedGenre = normalizeTrackGenreName(widget.initialGenre);
    _genre = kPlaylistGenreNames.contains(normalizedGenre)
        ? normalizedGenre!
        : kTrackGenreNone;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    Navigator.pop(
      context,
      PlaylistEditorResult(
        title: title,
        description: _descriptionController.text.trim(),
        visibility: _visibility,
        genre: _genre == kTrackGenreNone ? null : _genre,
        coverImagePath: _coverImagePath,
      ),
    );
  }

  Future<void> _pickCover() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    final file = result?.files.single;
    final path = file?.path?.trim();
    if (path == null || path.isEmpty) return;

    setState(() {
      _coverImagePath = path;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _CoverPicker(
            localPath: _coverImagePath,
            remoteUrl: widget.initialCoverImageUrl,
            onPick: _pickCover,
            onClearLocal: _coverImagePath == null
                ? null
                : () {
                    setState(() {
                      _coverImagePath = null;
                    });
                  },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Title',
              labelStyle: TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            minLines: 2,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Description',
              labelStyle: TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<PlaylistVisibility>(
            initialValue: _visibility,
            dropdownColor: const Color(0xFF222222),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Visibility',
              labelStyle: TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _visibility = value;
              });
            },
            items: PlaylistVisibility.values
                .map(
                  (visibility) => DropdownMenuItem<PlaylistVisibility>(
                    value: visibility,
                    child: Text(visibility.label),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue:
                kPlaylistGenreNames.contains(_genre) ? _genre : kTrackGenreNone,
            dropdownColor: const Color(0xFF222222),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Genre',
              labelStyle: TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _genre = value;
              });
            },
            items: kPlaylistGenreNames
                .map(
                  (genre) => DropdownMenuItem<String>(
                    value: genre,
                    child: Text(
                      genre == kTrackGenreNone ? 'No genre' : genre,
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5500),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _submit,
              child: Text(widget.submitLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverPicker extends StatelessWidget {
  const _CoverPicker({
    required this.localPath,
    required this.remoteUrl,
    required this.onPick,
    required this.onClearLocal,
  });

  final String? localPath;
  final String? remoteUrl;
  final VoidCallback onPick;
  final VoidCallback? onClearLocal;

  @override
  Widget build(BuildContext context) {
    final normalizedRemoteUrl = PlatformUrlUtils.normalizeBackendUrl(remoteUrl);
    final hasLocal = localPath != null && localPath!.trim().isNotEmpty;
    final hasRemote = normalizedRemoteUrl != null;

    Widget preview;
    if (hasLocal) {
      preview = Image.file(
        File(localPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image_outlined, color: Colors.white54),
      );
    } else if (hasRemote) {
      preview = Image.network(
        normalizedRemoteUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image_outlined, color: Colors.white54),
      );
    } else {
      preview = const Icon(Icons.image_outlined, color: Colors.white54);
    }

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 76,
            height: 76,
            color: Colors.white10,
            child: preview,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cover',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hasLocal
                    ? 'New cover selected'
                    : hasRemote
                        ? 'Current playlist cover'
                        : 'Optional playlist cover',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: onPick,
                    icon: const Icon(Icons.image_outlined, size: 16),
                    label: Text(hasLocal || hasRemote ? 'Replace' : 'Choose'),
                  ),
                  if (onClearLocal != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onClearLocal,
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white70,
                        size: 18,
                      ),
                      tooltip: 'Clear selected cover',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
