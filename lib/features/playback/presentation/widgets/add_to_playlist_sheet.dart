// features/playlist/presentation/widgets/add_to_playlist_sheet.dart

import 'package:flutter/material.dart';
import 'package:soundcloud_clone/core/models/track.dart';

import '../../data/repositories/playlist_repository.dart';

class AddToPlaylistSheet extends StatefulWidget {
  final Track track;

  const AddToPlaylistSheet({super.key, required this.track});

  static Future<void> show(BuildContext context, {required Track track}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => AddToPlaylistSheet(track: track),
    );
  }

  @override
  State<AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends State<AddToPlaylistSheet> {
  final _repo = PlaylistRepository.instance;
  final _nameController = TextEditingController();
  bool _showCreate = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addToPlaylist(String playlistId, String playlistName) {
    final added = _repo.addTrack(playlistId, widget.track);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF333333),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        content: Text(
          added ? 'Added to $playlistName' : 'Already in $playlistName',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _createAndAdd() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final playlist = _repo.createPlaylist(name);
    _repo.addTrack(playlist.id, widget.track);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF333333),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        content: Text(
          'Created "$name" and added track',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playlists = _repo.getAll();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add to playlist',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // New playlist button
                GestureDetector(
                  onTap: () => setState(() => _showCreate = !_showCreate),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white30),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'New playlist',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Create new playlist input
          if (_showCreate) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Playlist name',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _createAndAdd,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5500),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Create',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),

          // Playlist list
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: playlists.length,
              itemBuilder: (_, index) {
                final playlist = playlists[index];
                final alreadyAdded =
                    _repo.containsTrack(playlist.id, widget.track.id);

                return ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.queue_music,
                        color: Colors.white54, size: 20),
                  ),
                  title: Text(
                    playlist.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '${playlist.tracks.length} tracks',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  trailing: alreadyAdded
                      ? const Icon(Icons.check,
                          color: Color(0xFFFF5500), size: 20)
                      : null,
                  onTap: alreadyAdded
                      ? null
                      : () => _addToPlaylist(playlist.id, playlist.name),
                );
              },
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
