import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:soundcloud_clone/core/utils/platform_url_utils.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';
import 'package:soundcloud_clone/features/playlists/presentation/bloc/playlists_cubit.dart';
import 'package:soundcloud_clone/features/playlists/presentation/bloc/playlists_state.dart';
import 'package:soundcloud_clone/features/playlists/presentation/widgets/playlist_editor_sheet.dart';
import 'package:soundcloud_clone/features/playlists/presentation/widgets/playlist_track_picker_sheet.dart';

class PlaylistsPage extends StatefulWidget {
  const PlaylistsPage({super.key});

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlaylistsCubit>().loadMyPlaylists();
    });
  }

  Future<void> _createPlaylist() async {
    final existingTitles = context.read<PlaylistsCubit>().state.playlists;
    final result = await PlaylistEditorSheet.show(
      context,
      title: 'Create playlist',
      submitLabel: 'Create',
    );

    if (!mounted || result == null) return;

    final duplicate = existingTitles.any(
      (playlist) => _samePlaylistTitle(playlist.title, result.title),
    );
    if (duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('A playlist with this name already exists')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Choose tracks for this playlist')),
    );

    final selectedTracks = await PlaylistTrackPickerSheet.show(
      context,
      existingTrackIds: const <String>{},
    );

    if (!mounted || selectedTracks.isEmpty) return;

    final created = await context.read<PlaylistsCubit>().createPlaylist(
          title: result.title,
          description: result.description,
          visibility: result.visibility,
          genre: result.genre,
          coverImagePath: result.coverImagePath,
          initialTrackIds:
              selectedTracks.map((track) => track.id).toList(growable: false),
        );

    if (!mounted || created == null) return;

    context.push('/playlist/${created.playlistId}');
  }

  bool _samePlaylistTitle(String left, String right) {
    return left.trim().toLowerCase() == right.trim().toLowerCase();
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
        } else if (state.infoMessage != null && state.infoMessage!.isNotEmpty) {
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
        final playlists = state.playlists;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: const Text('Playlists'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: state.isSubmitting ? null : _createPlaylist,
              ),
            ],
          ),
          body: state.isLoadingMyPlaylists && playlists.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => context
                      .read<PlaylistsCubit>()
                      .loadMyPlaylists(refresh: true),
                  child: playlists.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Text(
                                'No playlists yet',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: playlists.length,
                          separatorBuilder: (_, __) =>
                              const Divider(color: Colors.white12, height: 1),
                          itemBuilder: (context, index) {
                            final playlist = playlists[index];
                            final subtitle = playlist.description.isEmpty
                                ? '${playlist.tracksCount} tracks'
                                : '${playlist.description} • ${playlist.tracksCount} tracks';

                            return ListTile(
                              leading: _PlaylistListCover(playlist: playlist),
                              title: Text(
                                playlist.title,
                                style: const TextStyle(color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                subtitle,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: Colors.white54,
                              ),
                              onTap: () {
                                context
                                    .push('/playlist/${playlist.playlistId}');
                              },
                            );
                          },
                        ),
                ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFFFF5500),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.library_add),
            onPressed: state.isSubmitting ? null : _createPlaylist,
            label: const Text('New Playlist'),
          ),
        );
      },
    );
  }
}

class _PlaylistListCover extends StatelessWidget {
  const _PlaylistListCover({required this.playlist});

  final PlaylistEntity playlist;

  @override
  Widget build(BuildContext context) {
    final coverUrl =
        PlatformUrlUtils.normalizeBackendUrl(playlist.coverImageUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 44,
        height: 44,
        color: Colors.grey.shade900,
        child: coverUrl == null
            ? Icon(
                playlist.visibility == PlaylistVisibility.privatePlaylist
                    ? Icons.lock_outline
                    : Icons.public,
                color: const Color(0xFFFF5500),
              )
            : Image.network(
                coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.queue_music,
                  color: Color(0xFFFF5500),
                ),
              ),
      ),
    );
  }
}
