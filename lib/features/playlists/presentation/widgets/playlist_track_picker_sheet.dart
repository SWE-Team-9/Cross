import 'dart:async';

import 'package:flutter/material.dart';
import 'package:soundcloud_clone/core/di/injector.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/playlists/data/datasources/playlist_track_search_remote_data_source.dart';

class PlaylistTrackPickerSheet extends StatefulWidget {
  final Set<String> existingTrackIds;

  const PlaylistTrackPickerSheet({
    super.key,
    required this.existingTrackIds,
  });

  static Future<Track?> show(
    BuildContext context, {
    required Set<String> existingTrackIds,
  }) {
    return showModalBottomSheet<Track>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return PlaylistTrackPickerSheet(existingTrackIds: existingTrackIds);
      },
    );
  }

  @override
  State<PlaylistTrackPickerSheet> createState() =>
      _PlaylistTrackPickerSheetState();
}

class _PlaylistTrackPickerSheetState extends State<PlaylistTrackPickerSheet> {
  late final TextEditingController _controller;
  late final PlaylistTrackSearchRemoteDataSource _searchDataSource;

  Timer? _debounce;
  List<Track> _results = const <Track>[];
  String _activeQuery = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _searchDataSource = PlaylistTrackSearchRemoteDataSource(getIt());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      _runSearch(value);
    });
  }

  Future<void> _runSearch(String query) async {
    final trimmed = query.trim();

    setState(() {
      _activeQuery = trimmed;
      if (trimmed.isEmpty) {
        _results = const <Track>[];
        _loading = false;
      } else {
        _loading = true;
      }
    });

    if (trimmed.isEmpty) return;

    try {
      final result = await _searchDataSource.searchTracks(trimmed);
      if (!mounted || _activeQuery != trimmed) return;
      setState(() {
        _results = result;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || _activeQuery != trimmed) return;
      setState(() {
        _results = const <Track>[];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            onChanged: _onQueryChanged,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search tracks by title or artist',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white10,
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _activeQuery.isEmpty
                    ? const Center(
                        child: Text(
                          'Start typing to search tracks',
                          style: TextStyle(color: Colors.white60),
                        ),
                      )
                    : _results.isEmpty
                        ? const Center(
                            child: Text(
                              'No tracks found',
                              style: TextStyle(color: Colors.white60),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _results.length,
                            itemBuilder: (_, index) {
                              final track = _results[index];
                              final exists =
                                  widget.existingTrackIds.contains(track.id);

                              return ListTile(
                                leading: track.artworkUrl == null
                                    ? Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF262626),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Icon(
                                          Icons.music_note,
                                          color: Colors.white38,
                                        ),
                                      )
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(
                                          track.artworkUrl!,
                                          width: 42,
                                          height: 42,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                title: Text(
                                  track.title,
                                  style: const TextStyle(color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  track.artist,
                                  style: const TextStyle(color: Colors.white60),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: exists
                                    ? const Icon(
                                        Icons.check,
                                        color: Color(0xFFFF5500),
                                      )
                                    : const Icon(
                                        Icons.add,
                                        color: Colors.white70,
                                      ),
                                onTap: exists
                                    ? null
                                    : () => Navigator.pop(context, track),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
