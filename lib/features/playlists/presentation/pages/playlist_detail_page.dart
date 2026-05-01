import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundcloud_clone/core/di/injector.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/utils/platform_url_utils.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_cubit.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_state.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';
import 'package:soundcloud_clone/features/playlists/presentation/bloc/playlists_cubit.dart';
import 'package:soundcloud_clone/features/playlists/presentation/bloc/playlists_state.dart';
import 'package:soundcloud_clone/features/playlists/presentation/widgets/playlist_editor_sheet.dart';
import 'package:soundcloud_clone/features/playlists/presentation/widgets/playlist_track_picker_sheet.dart';
import 'package:soundcloud_clone/features/messaging/presentation/widgets/share_track_to_conversation_sheet.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/subscription.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_cubit.dart';

class PlaylistDetailPage extends StatefulWidget {
  final String playlistId;
  final String? secretToken;

  const PlaylistDetailPage({
    super.key,
    required this.playlistId,
    this.secretToken,
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
      initialCoverImageUrl: editablePlaylist.coverImageUrl,
    );

    if (!mounted || result == null) return;

    await context.read<PlaylistsCubit>().updatePlaylist(
          playlistId: playlist.playlistId,
          title: result.title,
          description: result.description,
          visibility: result.visibility,
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

  Future<void> _playPlaylist(PlaylistEntity playlist,
      {int startIndex = 0}) async {
    final tracks = playlist.tracks;
    if (tracks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This playlist has no tracks')),
      );
      return;
    }

    final playerCubit = _playerCubit();
    await playerCubit?.playFromContext(
      tracks: tracks,
      startIndex: startIndex,
      source: 'playlist:${playlist.playlistId}',
    );
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
      _showPlaylistSnack('Playlist already downloaded');
      return;
    }

    setState(() => _isDownloadingPlaylist = true);

    var downloadedCount = 0;
    try {
      for (final track in missingTracks) {
        await offlineCubit.download(track.id);
        downloadedCount++;
      }

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

  Widget _buildDownloadPlaylistButton(
    PlaylistEntity playlist,
    bool isSubmitting,
  ) {
    final subscriptionCubit = _lookupCubit<SubscriptionCubit>();
    final offlineCubit = _lookupCubit<OfflineCubit>();
    if (subscriptionCubit == null || offlineCubit == null) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<SubscriptionCubit, Subscription?>(
      bloc: subscriptionCubit,
      builder: (context, subscription) {
        if (subscription?.canDownload != true) return const SizedBox.shrink();

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
        final playlist = state.selectedPlaylist;

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
                                      '${playlist.tracksCount} tracks',
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
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: state.isSubmitting
                          ? null
                          : () => _addCurrentTrack(playlist),
                      icon: const Icon(Icons.library_add, color: Colors.white),
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
                    : ReorderableListView.builder(
                        itemCount: tracks.length,
                        onReorder: (oldIndex, newIndex) {
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
                          final track = tracks[index];
                          return ListTile(
                            key: ValueKey(track.id),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                            ),
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ReorderableDragStartListener(
                                  index: index,
                                  child: const Icon(
                                    Icons.drag_indicator,
                                    color: Colors.white38,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                track.artworkUrl == null
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
                      ),
              ),
            ],
          ),
        );
      },
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
