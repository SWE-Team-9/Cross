import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/models/track.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/platform_url_utils.dart';
import '../../../interactions/domain/usecases/get_my_liked_tracks_usecase.dart';
import '../../../playlists/data/datasources/playlist_track_search_remote_data_source.dart';
import '../../../playlists/domain/entities/playlist_entity.dart';
import '../../../playlists/domain/repositories/playlists_repository.dart';
import '../../../upload/domain/entities/managed_track.dart';
import '../messaging_theme.dart';

typedef ShareTrackCallback = Future<void> Function(Track track);
typedef SharePlaylistCallback = Future<void> Function(PlaylistEntity playlist);

enum _ShareKind { tracks, playlists }

enum _ShareSource { mine, liked }

class ShareMessageItemSheet extends StatefulWidget {
  const ShareMessageItemSheet({
    super.key,
    required this.onShareTrack,
    required this.onSharePlaylist,
  });

  final ShareTrackCallback onShareTrack;
  final SharePlaylistCallback onSharePlaylist;

  static Future<void> show(
    BuildContext context, {
    required ShareTrackCallback onShareTrack,
    required SharePlaylistCallback onSharePlaylist,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: MessagingTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => ShareMessageItemSheet(
        onShareTrack: onShareTrack,
        onSharePlaylist: onSharePlaylist,
      ),
    );
  }

  @override
  State<ShareMessageItemSheet> createState() => _ShareMessageItemSheetState();
}

class _ShareMessageItemSheetState extends State<ShareMessageItemSheet> {
  late final TextEditingController _searchController;
  late final PlaylistTrackSearchRemoteDataSource _trackSearch;

  _ShareKind _kind = _ShareKind.tracks;
  _ShareSource _source = _ShareSource.mine;

  bool _isLoading = false;
  String? _error;
  List<Track> _myTracks = const <Track>[];
  List<Track> _likedTracks = const <Track>[];
  List<PlaylistEntity> _myPlaylists = const <PlaylistEntity>[];
  List<PlaylistEntity> _likedPlaylists = const <PlaylistEntity>[];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _trackSearch = PlaylistTrackSearchRemoteDataSource(GetIt.I<DioClient>());
    unawaited(_loadCurrentView());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentView() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_kind == _ShareKind.tracks) {
        if (_source == _ShareSource.mine) {
          final tracks = _myTracks.isEmpty
              ? await _trackSearch.getMyTracks(limit: 100)
              : _myTracks;
          if (!mounted) return;
          setState(() {
            _myTracks = tracks;
          });
        } else {
          final tracks =
              _likedTracks.isEmpty ? await _loadLikedTracks() : _likedTracks;
          if (!mounted) return;
          setState(() {
            _likedTracks = tracks;
          });
        }
      } else {
        final repository = GetIt.I<PlaylistsRepository>();
        if (_source == _ShareSource.mine) {
          final playlists = _myPlaylists.isEmpty
              ? await repository.getMyPlaylists(limit: 100)
              : _myPlaylists;
          if (!mounted) return;
          setState(() {
            _myPlaylists = playlists;
          });
        } else {
          final playlists = _likedPlaylists.isEmpty
              ? await repository.getLikedPlaylists(limit: 100)
              : _likedPlaylists;
          if (!mounted) return;
          setState(() {
            _likedPlaylists = playlists;
          });
        }
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<List<Track>> _loadLikedTracks() async {
    final managedTracks = await GetIt.I<GetMyLikedTracksUseCase>()();
    return managedTracks.map(_managedTrackToTrack).toList(growable: false);
  }

  void _setKind(_ShareKind kind) {
    if (_kind == kind) return;
    setState(() {
      _kind = kind;
      _error = null;
    });
    unawaited(_loadCurrentView());
  }

  void _setSource(_ShareSource source) {
    if (_source == source) return;
    setState(() {
      _source = source;
      _error = null;
    });
    unawaited(_loadCurrentView());
  }

  List<Track> get _visibleTracks {
    final tracks = _source == _ShareSource.mine ? _myTracks : _likedTracks;
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return tracks;
    return tracks.where((track) {
      return track.title.toLowerCase().contains(query) ||
          track.artist.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  List<PlaylistEntity> get _visiblePlaylists {
    final playlists =
        _source == _ShareSource.mine ? _myPlaylists : _likedPlaylists;
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return playlists;
    return playlists.where((playlist) {
      final owner = playlist.owner?.displayName.toLowerCase() ?? '';
      return playlist.title.toLowerCase().contains(query) ||
          owner.contains(query);
    }).toList(growable: false);
  }

  Future<void> _shareTrack(Track track) async {
    Navigator.pop(context);
    await widget.onShareTrack(track);
  }

  Future<void> _sharePlaylist(PlaylistEntity playlist) async {
    Navigator.pop(context);
    await widget.onSharePlaylist(playlist);
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.78;

    return SizedBox(
      height: height,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 14,
            right: 14,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Share',
                style: TextStyle(
                  color: MessagingTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _KindTabs(kind: _kind, onChanged: _setKind),
              const SizedBox(height: 10),
              _SourceTabs(source: _source, onChanged: _setSource),
              const SizedBox(height: 10),
              _SearchField(
                controller: _searchController,
                source: _source,
                kind: _kind,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              Expanded(child: _buildResults()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: MessagingTheme.accent),
      );
    }

    if (_error != null) {
      return _EmptyState(
        icon: Icons.error_outline,
        label: 'Unable to load items',
      );
    }

    if (_kind == _ShareKind.tracks) {
      final tracks = _visibleTracks;
      if (tracks.isEmpty) {
        return const _EmptyState(
          icon: Icons.music_note_outlined,
          label: 'No tracks found',
        );
      }
      return ListView.separated(
        itemCount: tracks.length,
        separatorBuilder: (_, __) =>
            const Divider(color: MessagingTheme.border, height: 1),
        itemBuilder: (context, index) {
          final track = tracks[index];
          return _TrackTile(
            track: track,
            onTap: () => _shareTrack(track),
          );
        },
      );
    }

    final playlists = _visiblePlaylists;
    if (playlists.isEmpty) {
      return const _EmptyState(
        icon: Icons.queue_music_outlined,
        label: 'No playlists found',
      );
    }
    return ListView.separated(
      itemCount: playlists.length,
      separatorBuilder: (_, __) =>
          const Divider(color: MessagingTheme.border, height: 1),
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return _PlaylistTile(
          playlist: playlist,
          onTap: () => _sharePlaylist(playlist),
        );
      },
    );
  }
}

class _KindTabs extends StatelessWidget {
  const _KindTabs({required this.kind, required this.onChanged});

  final _ShareKind kind;
  final ValueChanged<_ShareKind> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PillButton(
            label: 'Tracks',
            icon: Icons.music_note,
            selected: kind == _ShareKind.tracks,
            onTap: () => onChanged(_ShareKind.tracks),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PillButton(
            label: 'Playlists',
            icon: Icons.queue_music,
            selected: kind == _ShareKind.playlists,
            onTap: () => onChanged(_ShareKind.playlists),
          ),
        ),
      ],
    );
  }
}

class _SourceTabs extends StatelessWidget {
  const _SourceTabs({required this.source, required this.onChanged});

  final _ShareSource source;
  final ValueChanged<_ShareSource> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PillButton(
            label: 'Mine',
            icon: Icons.person_outline,
            selected: source == _ShareSource.mine,
            onTap: () => onChanged(_ShareSource.mine),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PillButton(
            label: 'Liked',
            icon: Icons.favorite_border,
            selected: source == _ShareSource.liked,
            onTap: () => onChanged(_ShareSource.liked),
          ),
        ),
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: selected ? MessagingTheme.accentSoft : MessagingTheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? MessagingTheme.accent : MessagingTheme.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? MessagingTheme.accent : Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.source,
    required this.kind,
    required this.onChanged,
  });

  final TextEditingController controller;
  final _ShareSource source;
  final _ShareKind kind;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final itemLabel = kind == _ShareKind.tracks ? 'tracks' : 'playlists';
    final sourceLabel = source == _ShareSource.mine ? 'your' : 'liked';

    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search $sourceLabel $itemLabel',
        hintStyle: const TextStyle(color: MessagingTheme.textMuted),
        prefixIcon: const Icon(Icons.search, color: MessagingTheme.textMuted),
        filled: true,
        fillColor: MessagingTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: MessagingTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: MessagingTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: MessagingTheme.accent),
        ),
      ),
    );
  }
}

Track _managedTrackToTrack(ManagedTrack track) {
  return Track(
    id: track.id,
    title: track.title,
    artist: track.artistName ?? track.artistHandle ?? 'Unknown artist',
    audioUrl: '',
    artworkUrl: track.artworkUrl,
    handle: track.artistHandle,
    likesCount: track.likesCount,
    repostsCount: track.repostsCount,
    durationMs: track.durationInSeconds == null
        ? null
        : track.durationInSeconds! * 1000,
  );
}

class _TrackTile extends StatelessWidget {
  const _TrackTile({required this.track, required this.onTap});

  final Track track;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final artworkUrl = PlatformUrlUtils.normalizeBackendUrl(track.artworkUrl);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _ArtworkBox(
        imageUrl: artworkUrl,
        fallbackIcon: Icons.music_note,
      ),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        track.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: MessagingTheme.textMuted, fontSize: 12),
      ),
      trailing: const Icon(Icons.send_rounded, color: MessagingTheme.accent),
      onTap: onTap,
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  const _PlaylistTile({required this.playlist, required this.onTap});

  final PlaylistEntity playlist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final coverUrl =
        PlatformUrlUtils.normalizeBackendUrl(playlist.coverImageUrl);
    final owner = playlist.owner?.displayName.trim();

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _ArtworkBox(
        imageUrl: coverUrl,
        fallbackIcon: playlist.visibility.isSecret
            ? Icons.lock_outline
            : Icons.queue_music,
      ),
      title: Text(
        playlist.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        owner != null && owner.isNotEmpty
            ? owner
            : '${playlist.tracksCount} tracks',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: MessagingTheme.textMuted, fontSize: 12),
      ),
      trailing: const Icon(Icons.send_rounded, color: MessagingTheme.accent),
      onTap: onTap,
    );
  }
}

class _ArtworkBox extends StatelessWidget {
  const _ArtworkBox({
    required this.imageUrl,
    required this.fallbackIcon,
  });

  final String? imageUrl;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 48,
        height: 48,
        color: MessagingTheme.surfaceAlt,
        child: imageUrl == null
            ? Icon(fallbackIcon, color: MessagingTheme.accent)
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(fallbackIcon, color: MessagingTheme.accent),
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white24, size: 42),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: MessagingTheme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
