import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:soundcloud_clone/core/di/injector.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/core/utils/platform_url_utils.dart';
import 'package:soundcloud_clone/core/widgets/app_network_image.dart';
import 'package:soundcloud_clone/core/widgets/track_row.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playlists/data/local/recent_playlists_store.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';
import 'package:soundcloud_clone/features/playlists/presentation/bloc/playlists_cubit.dart';
import 'package:soundcloud_clone/features/playlists/presentation/bloc/playlists_state.dart';
import 'package:soundcloud_clone/features/playlists/presentation/widgets/playlist_editor_sheet.dart';
import 'package:soundcloud_clone/features/playlists/presentation/widgets/playlist_track_picker_sheet.dart';
import 'package:soundcloud_clone/features/messaging/presentation/widgets/share_track_to_conversation_sheet.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_genre.dart';

class PlaylistDetailPage extends StatefulWidget {
  final String playlistId;
  final String? secretToken;
  final PlaylistEntity? initialPlaylist;

  const PlaylistDetailPage({
    super.key,
    required this.playlistId,
    this.secretToken,
    this.initialPlaylist,
  });

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  bool _isDownloadingPlaylist = false;
  bool _isShuffleEnabled = false;
  bool _showFullDescription = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.secretToken != null && widget.secretToken!.trim().isNotEmpty) {
        context
            .read<PlaylistsCubit>()
            .resolveSecretPlaylist(widget.secretToken!.trim());
        return;
      }
      if (widget.initialPlaylist != null) return;
      context.read<PlaylistsCubit>().loadPlaylistDetails(widget.playlistId);
    });
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _editPlaylist(PlaylistEntity playlist) async {
    final editDetails =
        await context.read<PlaylistsCubit>().loadPlaylistEditDetails(
              playlist.playlistId,
            );
    if (!mounted) return;

    final editablePlaylist = editDetails ?? playlist;
    final result = await PlaylistEditorSheet.show(
      context,
      title: 'Edit playlist',
      submitLabel: 'Save',
      initialTitle: editablePlaylist.title,
      initialDescription: editablePlaylist.description,
      initialVisibility: editablePlaylist.visibility,
      initialGenre: editablePlaylist.genre,
      initialCoverImageUrl: editablePlaylist.coverImageUrl,
    );

    if (!mounted || result == null) return;

    await context.read<PlaylistsCubit>().updatePlaylist(
          playlistId: playlist.playlistId,
          title: result.title,
          description: result.description,
          visibility: result.visibility,
          genre: result.genre,
          coverImagePath: result.coverImagePath,
        );
  }

  Future<void> _sharePlaylist(PlaylistEntity playlist) async {
    await showSharePlaylistToConversationSheet(
      context: context,
      playlistId: playlist.playlistId,
    );
  }

  Future<void> _deletePlaylist(String playlistId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Delete playlist?',
            style: TextStyle(color: Colors.white)),
        content: const Text('This action cannot be undone.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;
    await context.read<PlaylistsCubit>().deletePlaylist(playlistId);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _copySecretLink(String token) async {
    final link = 'soundclone://playlist/secret/$token';
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Secret link copied')));
  }

  Future<void> _openEmbedCode(String playlistId) async {
    await context.read<PlaylistsCubit>().loadEmbedCode(playlistId);
    final embedCode = context.read<PlaylistsCubit>().state.embedCode ?? '';
    if (!mounted || embedCode.trim().isEmpty) return;

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title:
            const Text('Embed code', style: TextStyle(color: Colors.white)),
        content: SelectableText(embedCode,
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: embedCode));
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Embed code copied')));
            },
            child: const Text('Copy'),
          ),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _addCurrentTrack(PlaylistEntity playlist) async {
    Track? currentTrack;
    try {
      currentTrack = context.read<PlayerCubit>().state.currentTrack;
    } catch (_) {
      if (getIt.isRegistered<PlayerCubit>()) {
        currentTrack = getIt<PlayerCubit>().state.currentTrack;
      }
    }

    if (currentTrack == null) {
      _showSnack('No active track to add');
      return;
    }

    final exists = playlist.tracks.any((t) => t.id == currentTrack!.id);
    if (exists) {
      _showSnack('Track is already in this playlist');
      return;
    }

    await context.read<PlaylistsCubit>().addTrackToPlaylist(
          playlistId: playlist.playlistId,
          track: currentTrack,
        );
  }

  Future<void> _openTrackPicker(PlaylistEntity playlist) async {
    final pickedTracks = await PlaylistTrackPickerSheet.show(
      context,
      existingTrackIds: playlist.tracks.map((t) => t.id).toSet(),
    );

    if (!mounted || pickedTracks.isEmpty) return;

    var addedCount = 0;
    for (final track in pickedTracks) {
      final added = await context.read<PlaylistsCubit>().addTrackToPlaylist(
            playlistId: playlist.playlistId,
            track: track,
          );
      if (added) addedCount++;
    }

    if (mounted && addedCount > 0) {
      _showSnack('Added $addedCount track(s)');
    }
  }

  Future<void> _playPlaylist(
    PlaylistEntity playlist, {
    int startIndex = 0,
    bool shuffle = false,
  }) async {
    final tracks = playlist.tracks;
    if (tracks.isEmpty) {
      _showSnack('This playlist has no tracks');
      return;
    }

    final playerCubit = _playerCubit();
    await const RecentPlaylistsStore().record(playlist);
    await context
        .read<PlaylistsCubit>()
        .recordPlaylistPlayback(playlist.playlistId);
    final playbackTracks =
        shuffle ? (List<Track>.from(tracks)..shuffle(Random())) : tracks;
    await playerCubit?.playFromContext(
      tracks: playbackTracks,
      startIndex: startIndex,
      source: shuffle
          ? 'playlist:${playlist.playlistId}:shuffle'
          : 'playlist:${playlist.playlistId}',
    );
  }

  Future<void> _downloadPlaylist(PlaylistEntity playlist) async {
    final offlineCubit = _lookupCubit<OfflineCubit>();
    if (offlineCubit == null) {
      _showSnack('Offline downloads are not available right now');
      return;
    }

    final missingTracks = playlist.tracks
        .where((t) => !offlineCubit.isDownloaded(t.id))
        .toList();

    if (missingTracks.isEmpty) {
      await offlineCubit.saveDownloadedPlaylist(playlist);
      _showSnack('Playlist already downloaded');
      return;
    }

    setState(() => _isDownloadingPlaylist = true);

    var downloadedCount = 0;
    try {
      for (final track in missingTracks) {
        await offlineCubit.downloadTrack(track);
        downloadedCount++;
      }
      await offlineCubit.saveDownloadedPlaylist(playlist);
      if (!mounted) return;
      _showSnack(
        downloadedCount == playlist.tracks.length
            ? 'Playlist saved for offline listening'
            : 'Saved $downloadedCount track(s) for offline listening',
      );
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('UPGRADE_REQUIRED')) {
        Navigator.pushNamed(context, '/upgrade');
      } else {
        _showSnack(
          downloadedCount == 0
              ? 'Playlist download failed'
              : 'Saved $downloadedCount track(s). Some downloads failed',
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloadingPlaylist = false);
    }
  }

  Future<void> _copyPlaylist(PlaylistEntity playlist) async {
    final mode = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Copy playlist',
            style: TextStyle(color: Colors.white)),
        content: const Text(
            'Save the playlist as it is, or edit the copied title and cover first.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, 'edit'),
              child: const Text('Modify first')),
          TextButton(
              onPressed: () => Navigator.pop(context, 'save'),
              child: const Text('Save as is')),
        ],
      ),
    );

    if (!mounted || mode == null) return;

    var title = playlist.title;
    var description = playlist.description;
    var visibility = playlist.visibility;
    var genre = playlist.genre;
    String? coverImagePath;

    if (mode == 'edit') {
      final result = await PlaylistEditorSheet.show(
        context,
        title: 'Copy playlist',
        submitLabel: 'Save copy',
        initialTitle: title,
        initialDescription: description,
        initialVisibility: visibility,
        initialGenre: genre,
        initialCoverImageUrl: playlist.coverImageUrl,
      );
      if (!mounted || result == null) return;
      title = result.title;
      description = result.description;
      visibility = result.visibility;
      genre = result.genre;
      coverImagePath = result.coverImagePath;
    }

    coverImagePath ??= await _downloadCoverForCopy(playlist.coverImageUrl);

    final created = await context.read<PlaylistsCubit>().createPlaylist(
          title: title,
          description: description,
          visibility: visibility,
          genre: genre,
          coverImagePath: coverImagePath,
          initialTrackIds:
              playlist.tracks.map((t) => t.id).toList(growable: false),
        );

    if (!mounted || created == null) return;
    _showSnack('Playlist copied to your library');
    final copiedPlaylist = created.copyWith(
      coverImageUrl: created.coverImageUrl ?? playlist.coverImageUrl,
      owner: created.owner ?? _currentOwner(),
      genre: created.genre ?? genre,
      genreId: created.genreId ?? playlistGenreId(genre),
      tracks: playlist.tracks,
      tracksCount: playlist.tracks.length,
    );
    if (!mounted) return;
    context.go('/playlist/${created.playlistId}', extra: copiedPlaylist);
  }

  Future<String?> _downloadCoverForCopy(String? coverImageUrl) async {
    final normalizedUrl = PlatformUrlUtils.normalizeBackendUrl(coverImageUrl);
    if (normalizedUrl == null || !getIt.isRegistered<DioClient>()) return null;
    try {
      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/playlist-cover-${DateTime.now().microsecondsSinceEpoch}.jpg';
      await getIt<DioClient>().dio.download(normalizedUrl, filePath);
      return filePath;
    } catch (_) {
      return null;
    }
  }

  Future<void> _removeTrack(PlaylistEntity playlist, Track track) async {
    await context.read<PlaylistsCubit>().removeTrackFromPlaylist(
          playlistId: playlist.playlistId,
          trackId: track.id,
        );
    if (!mounted) return;
    if (playlist.tracks.length <= 1) Navigator.pop(context);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  PlayerCubit? _playerCubit() {
    try {
      return context.read<PlayerCubit>();
    } catch (_) {
      if (getIt.isRegistered<PlayerCubit>()) return getIt<PlayerCubit>();
    }
    return null;
  }

  T? _lookupCubit<T extends Object>() {
    try {
      return context.read<T>();
    } catch (_) {
      if (getIt.isRegistered<T>()) return getIt<T>();
      return null;
    }
  }

  bool _isOwner(PlaylistEntity playlist) {
    final ownerId = playlist.owner?.id.trim();
    if (ownerId == null || ownerId.isEmpty) return false;
    try {
      final s = context.read<AuthCubit>().state;
      if (s is AuthAuthenticated) return s.user.id.trim() == ownerId;
    } catch (_) {
      if (getIt.isRegistered<AuthCubit>()) {
        final s = getIt<AuthCubit>().state;
        if (s is AuthAuthenticated) return s.user.id.trim() == ownerId;
      }
    }
    return false;
  }

  PlaylistOwner? _currentOwner() {
    try {
      final s = context.read<AuthCubit>().state;
      if (s is AuthAuthenticated) {
        final dn = s.user.displayName?.trim();
        return PlaylistOwner(
            id: s.user.id,
            displayName:
                (dn == null || dn.isEmpty) ? s.user.handle : dn);
      }
    } catch (_) {
      if (getIt.isRegistered<AuthCubit>()) {
        final s = getIt<AuthCubit>().state;
        if (s is AuthAuthenticated) {
          final dn = s.user.displayName?.trim();
          return PlaylistOwner(
              id: s.user.id,
              displayName:
                  (dn == null || dn.isEmpty) ? s.user.handle : dn);
        }
      }
    }
    return null;
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showMoreOptions(
      BuildContext context, PlaylistEntity playlist, bool isOwner,
      bool isSubmitting) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (isOwner) ...[
              _BottomSheetTile(
                icon: Icons.edit_outlined,
                label: 'Edit playlist',
                onTap: () {
                  Navigator.pop(context);
                  _editPlaylist(playlist);
                },
              ),
              _BottomSheetTile(
                icon: Icons.code,
                label: 'Get embed code',
                onTap: () {
                  Navigator.pop(context);
                  _openEmbedCode(playlist.playlistId);
                },
              ),
              _BottomSheetTile(
                icon: Icons.library_add,
                label: 'Add current track',
                onTap: () {
                  Navigator.pop(context);
                  _addCurrentTrack(playlist);
                },
              ),
              _BottomSheetTile(
                icon: Icons.search,
                label: 'Search and add track',
                onTap: () {
                  Navigator.pop(context);
                  _openTrackPicker(playlist);
                },
              ),
              if (playlist.visibility.isSecret &&
                  playlist.secretToken != null &&
                  playlist.secretToken!.isNotEmpty)
                _BottomSheetTile(
                  icon: Icons.link,
                  label: 'Copy secret link',
                  onTap: () {
                    Navigator.pop(context);
                    _copySecretLink(playlist.secretToken!);
                  },
                ),
              _BottomSheetTile(
                icon: Icons.delete_outline,
                label: 'Delete playlist',
                color: Colors.redAccent,
                onTap: () {
                  Navigator.pop(context);
                  _deletePlaylist(playlist.playlistId);
                },
              ),
            ] else ...[
              _BottomSheetTile(
                icon: Icons.copy_all,
                label: 'Copy playlist',
                onTap: () {
                  Navigator.pop(context);
                  _copyPlaylist(playlist);
                },
              ),
            ],
            _BottomSheetTile(
              icon: Icons.share_outlined,
              label: 'Share',
              onTap: () {
                Navigator.pop(context);
                _sharePlaylist(playlist);
              },
            ),
            _BottomSheetTile(
              icon: _isDownloadingPlaylist
                  ? Icons.downloading
                  : Icons.download_for_offline_outlined,
              label: 'Download playlist',
              onTap: isSubmitting || _isDownloadingPlaylist
                  ? null
                  : () {
                      Navigator.pop(context);
                      _downloadPlaylist(playlist);
                    },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlaylistsCubit, PlaylistsState>(
      listener: (context, state) {
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              backgroundColor: const Color(0xFF3D0000),
              content: Text(state.errorMessage!,
                  style: const TextStyle(color: Colors.white)),
            ));
          context.read<PlaylistsCubit>().clearFeedback();
          return;
        }
        if (state.infoMessage != null && state.infoMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              backgroundColor: const Color(0xFF1F2C18),
              content: Text(state.infoMessage!,
                  style: const TextStyle(color: Colors.white)),
            ));
          context.read<PlaylistsCubit>().clearFeedback();
        }
      },
      builder: (context, state) {
        final playlist = state.selectedPlaylist ?? widget.initialPlaylist;

        if (state.isLoadingDetails && playlist == null) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (playlist == null) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(backgroundColor: Colors.black),
            body: const Center(
              child: Text('Playlist not found',
                  style: TextStyle(color: Colors.white70)),
            ),
          );
        }

        final tracks = playlist.tracks;
        final isOwner = _isOwner(playlist);

        return Scaffold(
          backgroundColor: Colors.black,
          // ── AppBar: back + title + cast icon ──────────────────────────
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.maybePop(context),
            ),
            title: const Text(
              'Station',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.cast, color: Colors.white),
                onPressed: () {},
                tooltip: 'Cast',
              ),
            ],
          ),

          body: CustomScrollView(
            slivers: [
              // ── Header: cover + info ────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cover art
                      _PlaylistCover(coverImageUrl: playlist.coverImageUrl),
                      const SizedBox(width: 16),
                      // Title + subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              playlist.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                // Station badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.white38, width: 1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.radio,
                                          color: Colors.white70, size: 12),
                                      SizedBox(width: 3),
                                      Text(
                                        'Artist station',
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Total duration / track count
                                Text(
                                  '${playlist.tracksCount} tracks',
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Like / More / Shuffle / Play row ────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      // Like button
                      _IconLabelButton(
                        icon: playlist.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        label: '${playlist.likesCount}',
                        color: playlist.isLiked
                            ? Colors.redAccent
                            : Colors.white70,
                        onTap: state.isSubmitting
                            ? null
                            : () {
                                final cubit =
                                    context.read<PlaylistsCubit>();
                                if (playlist.isLiked) {
                                  cubit.unlikePlaylist(
                                      playlist.playlistId);
                                } else {
                                  cubit.likePlaylist(
                                      playlist.playlistId);
                                }
                              },
                      ),
                      const SizedBox(width: 16),
                      // More (3-dot)
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _showMoreOptions(
                            context, playlist, isOwner, state.isSubmitting),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.more_vert,
                              color: Colors.white70, size: 22),
                        ),
                      ),
                      const Spacer(),
                      // Shuffle
                      IconButton(
                        icon: Icon(
                          Icons.shuffle,
                          color: _isShuffleEnabled
                              ? const Color(0xFFFF5500)
                              : Colors.white70,
                          size: 26,
                        ),
                        onPressed: tracks.isEmpty
                            ? null
                            : () => setState(
                                () => _isShuffleEnabled = !_isShuffleEnabled),
                        tooltip: 'Shuffle',
                      ),
                      const SizedBox(width: 8),
                      // Play button
                      GestureDetector(
                        onTap: tracks.isEmpty || state.isSubmitting
                            ? null
                            : () => _playPlaylist(playlist,
                                shuffle: _isShuffleEnabled),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow,
                              color: Colors.black, size: 30),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Description ("Based on …" + Show more) ──────────────
              if (playlist.description.isNotEmpty ||
                  playlist.owner?.displayName != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlist.description.isNotEmpty
                              ? playlist.description
                              : 'Based on ${playlist.owner?.displayName ?? playlist.title}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                          maxLines: _showFullDescription ? null : 2,
                          overflow: _showFullDescription
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => setState(() =>
                              _showFullDescription = !_showFullDescription),
                          child: Text(
                            _showFullDescription ? 'Show less' : 'Show more',
                            style: const TextStyle(
                              color: Color(0xFF4C9EFF),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // ── Track list ──────────────────────────────────────────
              tracks.isEmpty
                  ? const SliverFillRemaining(
                      child: Center(
                        child: Text('No tracks in this playlist yet',
                            style: TextStyle(color: Colors.white60)),
                      ),
                    )
                  : isOwner
                      ? SliverReorderableList(
                          itemCount:
                              tracks.length + (state.hasMorePlaylistTracks ? 1 : 0),
                          onReorder: (oldIndex, newIndex) {
                            if (oldIndex >= tracks.length ||
                                newIndex > tracks.length) return;
                            final nextTracks = tracks.toList(growable: true);
                            if (newIndex > oldIndex) newIndex -= 1;
                            final moved = nextTracks.removeAt(oldIndex);
                            nextTracks.insert(newIndex, moved);
                            context.read<PlaylistsCubit>().reorderTracks(
                                  playlistId: playlist.playlistId,
                                  orderedTracks: nextTracks,
                                );
                          },
                          itemBuilder: (context, index) {
                            if (index >= tracks.length) {
                              return _LoadMoreTile(
                                key: const ValueKey('load-more'),
                                isLoading:
                                    state.isLoadingMorePlaylistTracks,
                                onPressed: state.isLoadingMorePlaylistTracks
                                    ? null
                                    : () => context
                                        .read<PlaylistsCubit>()
                                        .loadMorePlaylistTracks(),
                              );
                            }
                            final track = tracks[index];
                            return TrackRow(
                              key: ValueKey(track.id),
                              track: track,
                              customOnTap: () =>
                                  _playPlaylist(playlist, startIndex: index),
                              reorderableIndex: index,
                              customTrailing: IconButton(
                                icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.redAccent),
                                onPressed: state.isSubmitting
                                    ? null
                                    : () => _removeTrack(playlist, track),
                              ),
                            );
                          },
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index >= tracks.length) {
                                return _LoadMoreTile(
                                  isLoading: state.isLoadingMorePlaylistTracks,
                                  onPressed: state.isLoadingMorePlaylistTracks
                                      ? null
                                      : () => context
                                          .read<PlaylistsCubit>()
                                          .loadMorePlaylistTracks(),
                                );
                              }
                              final track = tracks[index];
                              return TrackRow(
                                track: track,
                                customOnTap: () => _playPlaylist(playlist,
                                    startIndex: index),
                              );
                            },
                            childCount: tracks.length +
                                (state.hasMorePlaylistTracks ? 1 : 0),
                          ),
                        ),

              // Bottom padding so last item isn't hidden behind mini-player
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

/// Cover art square (matches SoundCloud station art – slightly larger)
class _PlaylistCover extends StatelessWidget {
  const _PlaylistCover({required this.coverImageUrl});
  final String? coverImageUrl;

  @override
  Widget build(BuildContext context) {
    final url = PlatformUrlUtils.normalizeBackendUrl(coverImageUrl);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 100,
        height: 100,
        color: const Color(0xFF262626),
        child: url == null
            ? const Icon(Icons.queue_music, color: Colors.white38, size: 40)
            : AppNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorWidget: (_) => const Icon(Icons.queue_music,
                    color: Colors.white38, size: 40),
              ),
      ),
    );
  }
}

/// Icon + label pair (like count, etc.)
class _IconLabelButton extends StatelessWidget {
  const _IconLabelButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

/// "Load more tracks" button row
class _LoadMoreTile extends StatelessWidget {
  const _LoadMoreTile({super.key, required this.isLoading, required this.onPressed});
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.expand_more, color: Colors.white),
        label: Text(
          isLoading ? 'Loading tracks...' : 'Load more tracks',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

/// Row item in the bottom-sheet options menu
class _BottomSheetTile extends StatelessWidget {
  const _BottomSheetTile({
    required this.icon,
    required this.label,
    this.color,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return ListTile(
      leading: Icon(icon, color: c),
      title: Text(label, style: TextStyle(color: c, fontSize: 15)),
      onTap: onTap,
    );
  }
}

