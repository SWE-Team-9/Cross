import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundcloud_clone/core/di/injector.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/utils/platform_url_utils.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';
import 'package:soundcloud_clone/features/playlists/presentation/bloc/playlists_cubit.dart';
import 'package:soundcloud_clone/features/playlists/presentation/bloc/playlists_state.dart';
import 'package:soundcloud_clone/features/playlists/presentation/widgets/playlist_editor_sheet.dart';

class AddToPlaylistSheet extends StatefulWidget {
  final Track track;

  const AddToPlaylistSheet({super.key, required this.track});

  static Future<void> show(BuildContext context, {required Track track}) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true, // ← fixes mini player showing on top
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BlocProvider<PlaylistsCubit>(
        create: (_) => getIt<PlaylistsCubit>()..loadMyPlaylists(),
        child: AddToPlaylistSheet(track: track),
      ),
    );
  }

  @override
  State<AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends State<AddToPlaylistSheet> {
  Future<void> _addToPlaylist(String playlistId, String playlistTitle) async {
    final added = await context.read<PlaylistsCubit>().addTrackToPlaylist(
          playlistId: playlistId,
          track: widget.track,
        );

    if (!mounted || !added) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF333333),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        content: Text(
          'Added to $playlistTitle',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _createAndAdd() async {
    final result = await PlaylistEditorSheet.show(
      context,
      title: 'Create playlist',
      submitLabel: 'Create',
    );

    if (!mounted || result == null) return;

    final playlist = await context.read<PlaylistsCubit>().createPlaylist(
      title: result.title,
      description: result.description,
      visibility: result.visibility,
      coverImagePath: result.coverImagePath,
      initialTrackIds: [widget.track.id],
    );

    if (!mounted || playlist == null) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF333333),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        content: Text(
          'Created "${playlist.title}" with "${widget.track.title}"',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlaylistsCubit, PlaylistsState>(
      listener: (context, state) {
        if (state.errorMessage == null || state.errorMessage!.trim().isEmpty) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF3D0000),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            content: Text(
              state.errorMessage!,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );

        context.read<PlaylistsCubit>().clearFeedback();
      },
      builder: (context, state) {
        final playlists = state.playlists;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                    GestureDetector(
                      onTap: state.isSubmitting ? null : _createAndAdd,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
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
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (state.isLoadingMyPlaylists)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(),
                )
              else if (playlists.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No playlists found',
                    style: TextStyle(color: Colors.white60),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: playlists.length,
                    itemBuilder: (_, index) {
                      final playlist = playlists[index];
                      final alreadyAdded = playlist.tracks
                          .any((track) => track.id == widget.track.id);

                      return ListTile(
                        leading: _PlaylistCoverThumb(playlist: playlist),
                        title: Text(
                          playlist.title,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '${playlist.tracksCount} tracks',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                        trailing: alreadyAdded
                            ? const Icon(
                                Icons.check,
                                color: Color(0xFFFF5500),
                                size: 20,
                              )
                            : null,
                        onTap: alreadyAdded || state.isSubmitting
                            ? null
                            : () => _addToPlaylist(
                                playlist.playlistId, playlist.title),
                      );
                    },
                  ),
                ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        );
      },
    );
  }
}

class _PlaylistCoverThumb extends StatelessWidget {
  const _PlaylistCoverThumb({required this.playlist});

  final PlaylistEntity playlist;

  @override
  Widget build(BuildContext context) {
    final coverUrl =
        PlatformUrlUtils.normalizeBackendUrl(playlist.coverImageUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 44,
        height: 44,
        color: Colors.grey[800],
        child: coverUrl == null
            ? Icon(
                playlist.visibility == PlaylistVisibility.privatePlaylist
                    ? Icons.lock_outline
                    : Icons.queue_music,
                color: Colors.white54,
                size: 20,
              )
            : Image.network(
                coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.queue_music,
                  color: Colors.white54,
                  size: 20,
                ),
              ),
      ),
    );
  }
}
