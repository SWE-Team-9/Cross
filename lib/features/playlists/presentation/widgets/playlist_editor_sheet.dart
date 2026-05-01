import 'package:flutter/material.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';

class PlaylistEditorResult {
  final String title;
  final String description;
  final PlaylistVisibility visibility;

  const PlaylistEditorResult({
    required this.title,
    required this.description,
    required this.visibility,
  });
}

class PlaylistEditorSheet extends StatefulWidget {
  final String title;
  final String submitLabel;
  final String initialTitle;
  final String initialDescription;
  final PlaylistVisibility initialVisibility;

  const PlaylistEditorSheet({
    super.key,
    required this.title,
    required this.submitLabel,
    this.initialTitle = '',
    this.initialDescription = '',
    this.initialVisibility = PlaylistVisibility.publicPlaylist,
  });

  static Future<PlaylistEditorResult?> show(
    BuildContext context, {
    required String title,
    required String submitLabel,
    String initialTitle = '',
    String initialDescription = '',
    PlaylistVisibility initialVisibility = PlaylistVisibility.publicPlaylist,
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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _descriptionController =
        TextEditingController(text: widget.initialDescription);
    _visibility = widget.initialVisibility;
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
      ),
    );
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
