import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundcloud_clone/core/di/injector.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/playlists/data/datasources/playlist_track_search_remote_data_source.dart';

class PlaylistTrackPickerSheet extends StatefulWidget {
  final Set<String> existingTrackIds;

  const PlaylistTrackPickerSheet({
    super.key,
    required this.existingTrackIds,
  });

  static Future<List<Track>> show(
    BuildContext context, {
    required Set<String> existingTrackIds,
  }) {
    return showModalBottomSheet<List<Track>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return PlaylistTrackPickerSheet(existingTrackIds: existingTrackIds);
      },
    ).then((tracks) => tracks ?? const <Track>[]);
  }

  @override
  State<PlaylistTrackPickerSheet> createState() =>
      _PlaylistTrackPickerSheetState();
}

class _PlaylistTrackPickerSheetState extends State<PlaylistTrackPickerSheet> {
  late final TextEditingController _controller;
  late final PlaylistTrackSearchRemoteDataSource _searchDataSource;

  Timer? _debounce;
  List<Track> _myTracks = const <Track>[];
  List<Track> _results = const <Track>[];
  final Map<String, Track> _selectedTracks = <String, Track>{};
  String _activeQuery = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _searchDataSource = PlaylistTrackSearchRemoteDataSource(getIt());
    _loadMyTracks();
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

  Future<void> _loadMyTracks() async {
    setState(() {
      _loading = true;
    });

    try {
      final tracks = await _searchDataSource.getMyTracks(
        userId: _currentUserId(),
      );
      if (!mounted) return;
      setState(() {
        _myTracks = tracks;
        if (_activeQuery.isEmpty) {
          _results = tracks;
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _myTracks = const <Track>[];
        if (_activeQuery.isEmpty) {
          _results = const <Track>[];
        }
        _loading = false;
      });
    }
  }

  String? _currentUserId() {
    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthAuthenticated) {
        final id = authState.user.id.trim();
        return id.isEmpty ? null : id;
      }
    } catch (_) {}

    return null;
  }

  Future<void> _runSearch(String query) async {
    final trimmed = query.trim();

    setState(() {
      _activeQuery = trimmed;
      if (trimmed.isEmpty) {
        _results = _myTracks;
        _loading = false;
      } else {
        _loading = true;
      }
    });

    if (trimmed.isEmpty) return;

    final localMatches = _filterTracks(_myTracks, trimmed);
    if (localMatches.isNotEmpty) {
      setState(() {
        _results = localMatches;
        _loading = false;
      });
      return;
    }

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

  List<Track> _filterTracks(List<Track> tracks, String query) {
    final normalized = query.toLowerCase();
    return tracks.where((track) {
      return track.title.toLowerCase().contains(normalized) ||
          track.artist.toLowerCase().contains(normalized);
    }).toList(growable: false);
  }

  void _toggleTrack(Track track) {
    if (widget.existingTrackIds.contains(track.id)) return;

    setState(() {
      if (_selectedTracks.containsKey(track.id)) {
        _selectedTracks.remove(track.id);
      } else {
        _selectedTracks[track.id] = track;
      }
    });
  }

  void _submitSelection() {
    Navigator.pop(
      context,
      _selectedTracks.values.toList(growable: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = mediaQuery.viewInsets.bottom;
    final sheetHeight =
        (mediaQuery.size.height * 0.86 - keyboardInset).clamp(280.0, 640.0);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: sheetHeight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
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
                if (_selectedTracks.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_selectedTracks.length} selected',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _results.isEmpty
                          ? const Center(
                              child: Text(
                                'No tracks found',
                                style: TextStyle(color: Colors.white60),
                              ),
                            )
                          : ListView.builder(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              itemCount: _results.length,
                              itemBuilder: (_, index) {
                                final track = _results[index];
                                final exists =
                                    widget.existingTrackIds.contains(track.id);
                                final selected =
                                    _selectedTracks.containsKey(track.id);

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
                                          borderRadius:
                                              BorderRadius.circular(6),
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
                                    style:
                                        const TextStyle(color: Colors.white60),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: exists
                                      ? const Icon(
                                          Icons.check,
                                          color: Color(0xFFFF5500),
                                        )
                                      : selected
                                          ? const Icon(
                                              Icons.check_circle,
                                              color: Color(0xFFFF5500),
                                            )
                                          : const Icon(
                                              Icons.add,
                                              color: Colors.white70,
                                            ),
                                  onTap:
                                      exists ? null : () => _toggleTrack(track),
                                );
                              },
                            ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5500),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.white12,
                      disabledForegroundColor: Colors.white38,
                    ),
                    onPressed: _selectedTracks.isEmpty
                        ? null
                        : () => _submitSelection(),
                    icon: const Icon(Icons.playlist_add_check),
                    label: Text(
                      _selectedTracks.length <= 1
                          ? 'Add selected track'
                          : 'Add ${_selectedTracks.length} tracks',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
