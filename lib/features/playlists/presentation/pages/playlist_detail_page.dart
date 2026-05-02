import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:soundcloud_clone/core/di/injector.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/core/utils/platform_url_utils.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_cubit.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_state.dart';
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
        title: const Text(
          'Delete playlist?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    await context.read<PlaylistsCubit>().deletePlaylist(playlistId);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _copySecretLink(String token) async {
    final link = 'soundclone://playlist/secret/$token';
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Secret link copied')),
    );
  }

  Future<void> _openEmbedCode(String playlistId) async {
    await context.read<PlaylistsCubit>().loadEmbedCode(playlistId);
    final embedCode = context.read<PlaylistsCubit>().state.embedCode ?? '';
    if (!mounted || embedCode.trim().isEmpty) return;

    await showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Embed code',
            style: TextStyle(color: Colors.white),
          ),
          content: SelectableText(
            embedCode,
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: embedCode));
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Embed code copied')),
                );
              },
              child: const Text('Copy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active track to add')),
      );
      return;
    }

    final exists = playlist.tracks.any((track) => track.id == currentTrack!.id);
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Track is already in this playlist')),
      );
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
      existingTrackIds: playlist.tracks.map((track) => track.id).toSet(),
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

    if (!mounted || addedCount == 0) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added $addedCount track(s)')),
    );
  }

  Future<void> _playPlaylist(
    PlaylistEntity playlist, {
    int startIndex = 0,
  }) async {
    final tracks = playlist.tracks;
    if (tracks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This playlist has no tracks')),
      );
      return;
    }

    final playerCubit = _playerCubit();
    await const RecentPlaylistsStore().record(playlist);
    await context
        .read<PlaylistsCubit>()
        .recordPlaylistPlayback(playlist.playlistId);
    await playerCubit?.playFromContext(
      tracks: tracks,
      startIndex: startIndex,
      source: 'playlist:${playlist.playlistId}',
    );
  }

  Future<void> _downloadTrack(Track track) async {
    final offlineCubit = _lookupCubit<OfflineCubit>();
    if (offlineCubit == null) {
      _showPlaylistSnack('Offline downloads are not available right now');
      return;
    }

    if (offlineCubit.isDownloaded(track.id)) {
      _showPlaylistSnack('Track already downloaded');
      return;
    }

    try {
      await offlineCubit.downloadTrack(track);
      if (!mounted) return;
      _showPlaylistSnack('Track saved for offline listening');
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('UPGRADE_REQUIRED')) {
        Navigator.pushNamed(context, '/upgrade');
      } else {
        _showPlaylistSnack('Track download failed');
      }
    }
  }

  Future<void> _downloadPlaylist(PlaylistEntity playlist) async {
    final offlineCubit = _lookupCubit<OfflineCubit>();
    if (offlineCubit == null) {
      _showPlaylistSnack('Offline downloads are not available right now');
      return;
    }

    final missingTracks = playlist.tracks
        .where((track) => !offlineCubit.isDownloaded(track.id))
        .toList();

    if (missingTracks.isEmpty) {
      await offlineCubit.saveDownloadedPlaylist(playlist);
      _showPlaylistSnack('Playlist already downloaded');
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
      _showPlaylistSnack(
        downloadedCount == playlist.tracks.length
            ? 'Playlist saved for offline listening'
            : 'Saved $downloadedCount track(s) for offline listening',
      );
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('UPGRADE_REQUIRED')) {
        Navigator.pushNamed(context, '/upgrade');
      } else {
        _showPlaylistSnack(
          downloadedCount == 0
              ? 'Playlist download failed'
              : 'Saved $downloadedCount track(s). Some downloads failed',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloadingPlaylist = false);
      }
    }
  }

  Future<void> _copyPlaylist(PlaylistEntity playlist) async {
    final mode = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Copy playlist',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Save the playlist as it is, or edit the copied title and cover first.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'edit'),
            child: const Text('Modify first'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('Save as is'),
          ),
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
              playlist.tracks.map((track) => track.id).toList(growable: false),
        );

    if (!mounted || created == null) return;
    _showPlaylistSnack('Playlist copied to your library');
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
    if (normalizedUrl == null || !getIt.isRegistered<DioClient>()) {
      return null;
    }

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

  Widget _buildDownloadPlaylistButton(
    PlaylistEntity playlist,
    bool isSubmitting,
  ) {
    final offlineCubit = _lookupCubit<OfflineCubit>();
    if (offlineCubit == null) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<OfflineCubit, OfflineState>(
      bloc: offlineCubit,
      builder: (context, offlineState) {
        final total = playlist.tracks.length;
        final downloaded = playlist.tracks
            .where((track) => offlineCubit.isDownloaded(track.id))
            .length;
        final allDownloaded = total > 0 && downloaded == total;

        return OutlinedButton.icon(
          onPressed: total == 0 || isSubmitting || _isDownloadingPlaylist
              ? null
              : () => _downloadPlaylist(playlist),
          icon: _isDownloadingPlaylist
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  allDownloaded
                      ? Icons.download_done_rounded
                      : Icons.download_for_offline_outlined,
                  color: Colors.white,
                ),
          label: Text(
            allDownloaded
                ? 'Playlist downloaded'
                : downloaded > 0
                    ? 'Download playlist ($downloaded/$total)'
                    : 'Download playlist',
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }

  PlayerCubit? _playerCubit() {
    try {
      return context.read<PlayerCubit>();
    } catch (_) {
      if (getIt.isRegistered<PlayerCubit>()) {
        return getIt<PlayerCubit>();
      }
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
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthAuthenticated) {
        return authState.user.id.trim() == ownerId;
      }
    } catch (_) {
      if (getIt.isRegistered<AuthCubit>()) {
        final authState = getIt<AuthCubit>().state;
        if (authState is AuthAuthenticated) {
          return authState.user.id.trim() == ownerId;
        }
      }
    }

    return false;
  }

  PlaylistOwner? _currentOwner() {
    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthAuthenticated) {
        final displayName = authState.user.displayName?.trim();
        return PlaylistOwner(
          id: authState.user.id,
          displayName: displayName == null || displayName.isEmpty
              ? authState.user.handle
              : displayName,
        );
      }
    } catch (_) {
      if (getIt.isRegistered<AuthCubit>()) {
        final authState = getIt<AuthCubit>().state;
        if (authState is AuthAuthenticated) {
          final displayName = authState.user.displayName?.trim();
          return PlaylistOwner(
            id: authState.user.id,
            displayName: displayName == null || displayName.isEmpty
                ? authState.user.handle
                : displayName,
          );
        }
      }
    }
    return null;
  }

  Widget _buildTrackDownloadButton(Track track) {
    final offlineCubit = _lookupCubit<OfflineCubit>();
    if (offlineCubit == null) return const SizedBox.shrink();

    return BlocBuilder<OfflineCubit, OfflineState>(
      bloc: offlineCubit,
      builder: (context, offlineState) {
        final downloaded = offlineState.downloadedTracks.containsKey(track.id);
        return IconButton(
          tooltip: downloaded ? 'Track downloaded' : 'Download track',
          icon: Icon(
            downloaded
                ? Icons.download_done_rounded
                : Icons.download_for_offline_outlined,
            color: downloaded ? const Color(0xFFFF5500) : Colors.white70,
          ),
          onPressed: downloaded ? null : () => _downloadTrack(track),
        );
      },
    );
  }

  void _showPlaylistSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _removeTrack(PlaylistEntity playlist, Track track) async {
    await context.read<PlaylistsCubit>().removeTrackFromPlaylist(
          playlistId: playlist.playlistId,
          trackId: track.id,
        );

    if (!mounted) return;

    if (playlist.tracks.length <= 1) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlaylistsCubit, PlaylistsState>(
      listener: (context, state) {
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF3D0000),
                content: Text(
                  state.errorMessage!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          context.read<PlaylistsCubit>().clearFeedback();
          return;
        }

        if (state.infoMessage != null && state.infoMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF1F2C18),
                content: Text(
                  state.infoMessage!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
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
              child: Text(
                'Playlist not found',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        final tracks = playlist.tracks;
        final isOwner = _isOwner(playlist);

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: Text(
              playlist.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.code),
                  onPressed: state.isSubmitting
                      ? null
                      : () => _openEmbedCode(playlist.playlistId),
                  tooltip: 'Get embed code',
                ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed:
                    state.isSubmitting ? null : () => _sharePlaylist(playlist),
                tooltip: 'Share playlist',
              ),
              if (isOwner)
                IconButton(
                  icon: state.isLoadingEditDetails
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.edit_outlined),
                  onPressed: state.isSubmitting || state.isLoadingEditDetails
                      ? null
                      : () => _editPlaylist(playlist),
                  tooltip: 'Edit playlist',
                ),
              IconButton(
                icon: Icon(
                  playlist.isLiked ? Icons.favorite : Icons.favorite_border,
                  color: playlist.isLiked ? Colors.redAccent : null,
                ),
                onPressed: state.isSubmitting
                    ? null
                    : () {
                        final cubit = context.read<PlaylistsCubit>();
                        if (playlist.isLiked) {
                          cubit.unlikePlaylist(playlist.playlistId);
                        } else {
                          cubit.likePlaylist(playlist.playlistId);
                        }
                      },
                tooltip: playlist.isLiked ? 'Unlike playlist' : 'Like playlist',
              ),
              if (isOwner)
                PopupMenuButton<String>(
                  color: const Color(0xFF202020),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deletePlaylist(playlist.playlistId);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text(
                        'Delete playlist',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF161616),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PlaylistCover(coverImageUrl: playlist.coverImageUrl),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: playlist.visibility.isSecret
                                          ? const Color(0xFF4A2400)
                                          : const Color(0xFF0E2E20),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      playlist.visibility.isSecret
                                          ? 'Secret'
                                          : 'Public',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      '${playlist.tracksCount} tracks • ${playlist.likesCount} likes',
                                      style: const TextStyle(
                                        color: Colors.white60,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (playlist.description.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  playlist.description,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                              if (_playlistMetadataText(playlist)
                                  .isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _playlistMetadataText(playlist),
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (playlist.visibility.isSecret &&
                        playlist.secretToken != null &&
                        playlist.secretToken!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => _copySecretLink(playlist.secretToken!),
                        icon: const Icon(Icons.link, color: Colors.white),
                        label: const Text(
                          'Copy secret link',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: tracks.isEmpty || state.isSubmitting
                          ? null
                          : () => _playPlaylist(playlist),
                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                      label: const Text(
                        'Play playlist',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDownloadPlaylistButton(
                      playlist,
                      state.isSubmitting,
                    ),
                    if (!isOwner) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: state.isSubmitting
                            ? null
                            : () => _copyPlaylist(playlist),
                        icon: const Icon(Icons.copy_all, color: Colors.white),
                        label: const Text(
                          'Copy playlist',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                    if (isOwner) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: state.isSubmitting
                            ? null
                            : () => _addCurrentTrack(playlist),
                        icon:
                            const Icon(Icons.library_add, color: Colors.white),
                        label: const Text(
                          'Add current track',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: state.isSubmitting
                            ? null
                            : () => _openTrackPicker(playlist),
                        icon: const Icon(Icons.search, color: Colors.white),
                        label: const Text(
                          'Search and add track',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Expanded(
                child: tracks.isEmpty
                    ? const Center(
                        child: Text(
                          'No tracks in this playlist yet',
                          style: TextStyle(color: Colors.white60),
                        ),
                      )
                    : isOwner
                        ? ReorderableListView.builder(
                            itemCount: tracks.length +
                                (state.hasMorePlaylistTracks ? 1 : 0),
                            onReorder: (oldIndex, newIndex) {
                              if (oldIndex >= tracks.length ||
                                  newIndex > tracks.length) {
                                return;
                              }
                              final nextTracks = tracks.toList(growable: true);

                              if (newIndex > oldIndex) {
                                newIndex -= 1;
                              }

                              final moved = nextTracks.removeAt(oldIndex);
                              nextTracks.insert(newIndex, moved);

                              context.read<PlaylistsCubit>().reorderTracks(
                                    playlistId: playlist.playlistId,
                                    orderedTracks: nextTracks,
                                  );
                            },
                            itemBuilder: (context, index) {
                              if (index >= tracks.length) {
                                return _LoadMorePlaylistTracksTile(
                                  key: const ValueKey(
                                      'load-more-playlist-tracks'),
                                  isLoading: state.isLoadingMorePlaylistTracks,
                                  onPressed: state.isLoadingMorePlaylistTracks
                                      ? null
                                      : () => context
                                          .read<PlaylistsCubit>()
                                          .loadMorePlaylistTracks(),
                                );
                              }

                              final track = tracks[index];
                              return _PlaylistTrackTile(
                                key: ValueKey(track.id),
                                track: track,
                                index: index,
                                showDragHandle: true,
                                onTap: () => _playPlaylist(
                                  playlist,
                                  startIndex: index,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: state.isSubmitting
                                      ? null
                                      : () => _removeTrack(playlist, track),
                                ),
                              );
                            },
                          )
                        : ListView.builder(
                            itemCount: tracks.length +
                                (state.hasMorePlaylistTracks ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= tracks.length) {
                                return _LoadMorePlaylistTracksTile(
                                  isLoading: state.isLoadingMorePlaylistTracks,
                                  onPressed: state.isLoadingMorePlaylistTracks
                                      ? null
                                      : () => context
                                          .read<PlaylistsCubit>()
                                          .loadMorePlaylistTracks(),
                                );
                              }

                              final track = tracks[index];
                              return _PlaylistTrackTile(
                                track: track,
                                index: index,
                                showDragHandle: false,
                                onTap: () => _playPlaylist(
                                  playlist,
                                  startIndex: index,
                                ),
                                trailing: _buildTrackDownloadButton(track),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _playlistMetadataText(PlaylistEntity playlist) {
  final parts = <String>[];
  final genre = playlist.genre?.trim();
  if (genre != null && genre.isNotEmpty) parts.add(genre);
  if (playlist.releaseDate != null) {
    final date = playlist.releaseDate!;
    parts.add(
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    );
  }
  if (playlist.tags.isNotEmpty) {
    parts.addAll(playlist.tags.take(3).map((tag) => '#$tag'));
  }
  return parts.join(' • ');
}

class _PlaylistTrackTile extends StatelessWidget {
  const _PlaylistTrackTile({
    super.key,
    required this.track,
    required this.index,
    required this.showDragHandle,
    required this.onTap,
    required this.trailing,
  });

  final Track track;
  final int index;
  final bool showDragHandle;
  final VoidCallback onTap;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final artworkUrl = PlatformUrlUtils.normalizeBackendUrl(track.artworkUrl);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDragHandle) ...[
            ReorderableDragStartListener(
              index: index,
              child: const Icon(
                Icons.drag_indicator,
                color: Colors.white38,
              ),
            ),
            const SizedBox(width: 8),
          ],
          artworkUrl == null
              ? Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF262626),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.music_note,
                    color: Colors.white38,
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    artworkUrl,
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                  ),
                ),
        ],
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
      onTap: onTap,
      trailing: trailing,
    );
  }
}

class _LoadMorePlaylistTracksTile extends StatelessWidget {
  const _LoadMorePlaylistTracksTile({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

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
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.expand_more, color: Colors.white),
        label: Text(
          isLoading ? 'Loading tracks...' : 'Load more tracks',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class _PlaylistCover extends StatelessWidget {
  const _PlaylistCover({required this.coverImageUrl});

  final String? coverImageUrl;

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = PlatformUrlUtils.normalizeBackendUrl(coverImageUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 92,
        height: 92,
        color: const Color(0xFF262626),
        child: normalizedUrl == null
            ? const Icon(Icons.queue_music, color: Colors.white38, size: 34)
            : Image.network(
                normalizedUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.queue_music,
                  color: Colors.white38,
                  size: 34,
                ),
              ),
      ),
    );
  }
}
