// coverage:ignore-file
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:soundcloud_clone/core/widgets/bottom_nav_bar.dart';
import 'package:soundcloud_clone/core/network/api_constants.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playlists/data/local/recent_playlists_store.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';
import 'package:soundcloud_clone/features/playlists/domain/repositories/playlists_repository.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/get_recent_playlists_usecase.dart';
import 'package:soundcloud_clone/features/recently_played/presentation/bloc/recently_played_cubit.dart';
import 'package:soundcloud_clone/features/recently_played/presentation/widgets/recently_played_row.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/utils/platform_url_utils.dart';
import 'package:soundcloud_clone/features/settings/presentation/page/settings_page.dart';
import 'package:soundcloud_clone/features/profile/presentation/routes/profile_routes.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  late final RecentlyPlayedCubit _historyCubit;
  bool _isLoadingRecentPlaylists = false;
  List<PlaylistEntity> _recentPlaylists = const <PlaylistEntity>[];
  bool _isLoadingLikedPlaylists = false;
  List<PlaylistEntity> _likedPlaylists = const <PlaylistEntity>[];

  void _goToOwnProfile(AuthState state) {
    if (state is! AuthAuthenticated || state.user.handle.isEmpty) return;
    ProfileRoutes.goToProfile(context, state.user.handle);
  }

  @override
  void initState() {
    super.initState();
    _historyCubit = GetIt.I<RecentlyPlayedCubit>()..loadListeningHistory();
    _loadRecentPlaylists();
    _loadLikedPlaylists();
  }

  Future<void> _loadRecentPlaylists() async {
    final localPlaylists = await const RecentPlaylistsStore().load(limit: 10);
    if (mounted && localPlaylists.isNotEmpty) {
      setState(() {
        _recentPlaylists = localPlaylists;
      });
    }

    if (!GetIt.I.isRegistered<GetRecentPlaylistsUseCase>()) return;

    setState(() {
      _isLoadingRecentPlaylists = true;
    });

    try {
      final playlists = await GetIt.I<GetRecentPlaylistsUseCase>()(limit: 10);
      if (!mounted) return;
      setState(() {
        _recentPlaylists = _mergePlaylists(playlists, localPlaylists);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recentPlaylists = localPlaylists;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingRecentPlaylists = false;
      });
    }
  }

  Future<void> _loadLikedPlaylists() async {
    if (!GetIt.I.isRegistered<PlaylistsRepository>()) return;

    setState(() {
      _isLoadingLikedPlaylists = true;
    });

    try {
      final playlists =
          await GetIt.I<PlaylistsRepository>().getLikedPlaylists(limit: 20);
      if (!mounted) return;
      setState(() {
        _likedPlaylists = playlists;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _likedPlaylists = const <PlaylistEntity>[];
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingLikedPlaylists = false;
      });
    }
  }

  List<PlaylistEntity> _mergePlaylists(
    List<PlaylistEntity> primary,
    List<PlaylistEntity> fallback,
  ) {
    final merged = <PlaylistEntity>[];
    final seenIds = <String>{};

    for (final playlist in [...primary, ...fallback]) {
      if (playlist.playlistId.isEmpty || !seenIds.add(playlist.playlistId)) {
        continue;
      }
      merged.add(playlist);
      if (merged.length >= 10) break;
    }

    return merged;
  }

  Future<Track> _ensurePlayableTrack(Track track) async {
    if (GetIt.I.isRegistered<OfflineCubit>()) {
      final offlineCubit = GetIt.I<OfflineCubit>();
      final localPath = offlineCubit.getPath(track.id);
      if (localPath != null && localPath.trim().isNotEmpty) {
        return track.copyWith(localPath: localPath);
      }
    }

    if (track.audioUrl.trim().isNotEmpty) return track;

    try {
      final response = await GetIt.I<DioClient>().get(
        ApiConstants.playerTrackSourcePath(track.id),
      );
      final dynamic data = response.data;

      String? streamUrl;
      if (data is Map<String, dynamic>) {
        final nestedData = data['data'];
        final nestedMap =
            nestedData is Map ? Map<String, dynamic>.from(nestedData) : null;
        streamUrl = (data['streamUrl'] ?? nestedMap?['streamUrl'])?.toString();
      } else if (data is Map) {
        final typed = Map<String, dynamic>.from(data);
        final nestedData = typed['data'];
        final nestedMap =
            nestedData is Map ? Map<String, dynamic>.from(nestedData) : null;
        streamUrl = (typed['streamUrl'] ?? nestedMap?['streamUrl'])?.toString();
      }

      if (streamUrl != null && streamUrl.trim().isNotEmpty) {
        return track.copyWith(audioUrl: streamUrl.trim());
      }
    } catch (_) {
      // fallback to original track when source lookup fails
    }

    return track;
  }

  Future<void> _playTrack(Track track) async {
    final playableTrack = await _ensurePlayableTrack(track);
    if (!mounted) return;

    _historyCubit.addTrack(playableTrack);
    await context.read<PlayerCubit>().play(playableTrack);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _historyCubit,
      child: Scaffold(
        backgroundColor: Colors.black,
        // ── Shared Bottom Nav (index 3 = Library) ──────────────────────────
        bottomNavigationBar: const BottomNavBar(selected: 3),
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          title: const Text(
            'Library',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.cast, color: Colors.white70),
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white70),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<AuthCubit>(),
                      child: const SettingsPage(),
                    ),
                  ),
                );
              },
            ),
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                String? avatarUrl;
                String fallbackText = '?';

                if (state is AuthAuthenticated) {
                  avatarUrl = state.user.avatarUrl;
                  fallbackText = state.user.handle.isNotEmpty
                      ? state.user.handle.substring(0, 1).toUpperCase()
                      : '?';
                }

                final normalizedAvatarUrl =
                    PlatformUrlUtils.normalizeBackendUrl(avatarUrl);

                return GestureDetector(
                  onTap: () => _goToOwnProfile(state),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFFFF5500),
                      backgroundImage: normalizedAvatarUrl != null
                          ? NetworkImage(normalizedAvatarUrl)
                          : null,
                      child: normalizedAvatarUrl == null
                          ? Text(
                              fallbackText,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) => _LibraryItem(
                  title: 'Your likes',
                  onTap: () => _goToOwnProfile(state),
                ),
              ),
              _LibraryItem(
                title: 'Playlists',
                onTap: () => context.push('/playlists'),
              ),
              _LibraryItem(title: 'Albums', onTap: () {}),
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  return _LibraryItem(
                    title: 'Following',
                    onTap: () {
                      if (state is AuthAuthenticated) {
                        context.push('/following/${state.user.handle}');
                      }
                    },
                  );
                },
              ),
              _LibraryItem(
                title: 'Suggested users',
                onTap: () => context.push('/suggested-users'),
              ),
              _LibraryItem(title: 'Stations', onTap: () {}),
              _LibraryItem(title: 'Your insights', onTap: () {}),
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) => _LibraryItem(
                  title: 'Your uploads',
                  onTap: () => _goToOwnProfile(state),
                ),
              ),
              _LibraryItem(
                title: 'Downloaded tracks',
                onTap: () => context.push('/library/downloads/tracks'),
              ),
              _LibraryItem(
                title: 'Downloaded playlists',
                onTap: () => context.push('/library/downloads/playlists'),
              ),
              const SizedBox(height: 20),
              _PlaylistSection(
                title: 'Liked playlists',
                loading: _isLoadingLikedPlaylists,
                playlists: _likedPlaylists,
                emptyMessage: 'No liked playlists yet',
              ),
              const SizedBox(height: 20),
              BlocBuilder<RecentlyPlayedCubit, List<Track>>(
                builder: (context, tracks) {
                  if (tracks.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'No recently played tracks yet',
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }
                  return RecentlyPlayedRow(
                    tracks: tracks,
                    onTrackTap: _playTrack,
                  );
                },
              ),
              const SizedBox(height: 20),
              _RecentPlaylistsSection(
                loading: _isLoadingRecentPlaylists,
                playlists: _recentPlaylists,
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _LibraryItem({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: onTap,
    );
  }
}

class _PlaylistSection extends StatelessWidget {
  const _PlaylistSection({
    required this.title,
    required this.loading,
    required this.playlists,
    required this.emptyMessage,
    this.openOffline = false,
  });

  final String title;
  final bool loading;
  final List<PlaylistEntity> playlists;
  final String emptyMessage;
  final bool openOffline;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (loading && playlists.isEmpty)
          const SizedBox(
            height: 96,
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFFFF5500)),
            ),
          )
        else if (playlists.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              emptyMessage,
              style: const TextStyle(color: Colors.white54),
            ),
          )
        else
          SizedBox(
            height: 178,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: playlists.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return _RecentPlaylistCard(
                  playlist: playlists[index],
                  openOffline: openOffline,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _RecentPlaylistsSection extends StatelessWidget {
  const _RecentPlaylistsSection({
    required this.loading,
    required this.playlists,
  });

  final bool loading;
  final List<PlaylistEntity> playlists;

  @override
  Widget build(BuildContext context) {
    return _PlaylistSection(
      title: 'Recently played playlists',
      loading: loading,
      playlists: playlists,
      emptyMessage: 'No recently played playlists yet',
      openOffline: true,
    );
  }
}

class _RecentPlaylistCard extends StatelessWidget {
  const _RecentPlaylistCard({
    required this.playlist,
    this.openOffline = false,
  });

  final PlaylistEntity playlist;
  final bool openOffline;

  @override
  Widget build(BuildContext context) {
    final coverUrl =
        PlatformUrlUtils.normalizeBackendUrl(playlist.coverImageUrl);
    final owner = playlist.owner?.displayName.trim() ?? '';

    return GestureDetector(
      onTap: () => context.push(
        '/playlist/${playlist.playlistId}',
        extra: openOffline && playlist.tracks.isNotEmpty ? playlist : null,
      ),
      child: SizedBox(
        width: 132,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 132,
                height: 132,
                color: const Color(0xFF222222),
                child: coverUrl == null
                    ? const Icon(
                        Icons.queue_music,
                        color: Colors.white54,
                        size: 36,
                      )
                    : Image.network(
                        coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.queue_music,
                          color: Colors.white54,
                          size: 36,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              playlist.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              owner.isEmpty ? 'Playlist' : owner,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
