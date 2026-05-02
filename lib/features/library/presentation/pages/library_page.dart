// coverage:ignore-file
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/network/api_constants.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/core/utils/platform_url_utils.dart';
import 'package:soundcloud_clone/core/widgets/bottom_nav_bar.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/library/presentation/bloc/library_cubit.dart';
import 'package:soundcloud_clone/features/library/presentation/bloc/library_state.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';
import 'package:soundcloud_clone/features/profile/presentation/routes/profile_routes.dart';
import 'package:soundcloud_clone/features/recently_played/presentation/bloc/recently_played_cubit.dart';
import 'package:soundcloud_clone/features/recently_played/presentation/widgets/recently_played_row.dart';
import 'package:soundcloud_clone/features/settings/presentation/page/settings_page.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_cubit.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_state.dart';
import 'package:soundcloud_clone/features/premium/presentation/widgets/premium_aware_ad_banner.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  late final RecentlyPlayedCubit _historyCubit;
  late final LibraryCubit _libraryCubit;

  void _goToOwnProfile(AuthState state) {
    if (state is! AuthAuthenticated || state.user.handle.isEmpty) return;
    ProfileRoutes.goToProfile(context, state.user.handle);
  }

  @override
  void initState() {
    super.initState();
    _historyCubit = GetIt.I<RecentlyPlayedCubit>()..loadListeningHistory();
    _libraryCubit = GetIt.I<LibraryCubit>()..loadLibraryPlaylists();
  }

  @override
  void dispose() {
    _libraryCubit.close();
    super.dispose();
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
    return MultiBlocProvider(
      providers: [
        BlocProvider<RecentlyPlayedCubit>.value(value: _historyCubit),
        BlocProvider<LibraryCubit>.value(value: _libraryCubit),
      ],
      child: Scaffold(
        backgroundColor: Colors.black,
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
        body: BlocBuilder<LibraryCubit, LibraryState>(
          builder: (context, libraryState) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const PremiumAwareAdBanner(
                    title: 'Take your library offline',
                    subtitle:
                        'Upgrade to remove sponsored cards, download music, and unlock more uploads.',
                    actionLabel: 'Upgrade',
                  ),
                  BlocBuilder<AuthCubit, AuthState>(                    builder: (context, state) => _LibraryItem(
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
                  const _PremiumDownloadLibraryItem(
                    title: 'Downloaded tracks',
                    downloadsPath: '/library/downloads/tracks',
                    icon: Icons.download_for_offline_outlined,
                  ),
                  const _PremiumDownloadLibraryItem(
                    title: 'Downloaded playlists',
                    downloadsPath: '/library/downloads/playlists',
                    icon: Icons.queue_music,
                  ),                  const SizedBox(height: 20),
                  _PlaylistSection(
                    title: 'Liked playlists',
                    loading: libraryState.isLoadingLikedPlaylists,
                    playlists: libraryState.likedPlaylists,
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
                    loading: libraryState.isLoadingRecentPlaylists,
                    playlists: libraryState.recentPlaylists,
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            );
          },
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

class _PremiumDownloadLibraryItem extends StatelessWidget {
  const _PremiumDownloadLibraryItem({
    required this.title,
    required this.downloadsPath,
    required this.icon,
  });

  final String title;
  final String downloadsPath;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final subscriptionCubit = _subscriptionCubitOf(context);

    if (subscriptionCubit == null) {
      return _buildItem(
        context,
        canDownload: true,
        isLoading: false,
      );
    }

    return BlocBuilder<SubscriptionCubit, SubscriptionState>(
      bloc: subscriptionCubit,
      builder: (context, state) {
        return _buildItem(
          context,
          canDownload: state.subscription.canDownload,
          isLoading: state.isInitial || state.isLoading,
        );
      },
    );
  }

  SubscriptionCubit? _subscriptionCubitOf(BuildContext context) {
    try {
      return context.read<SubscriptionCubit>();
    } catch (_) {
      final getIt = GetIt.I;

      if (getIt.isRegistered<SubscriptionCubit>()) {
        return getIt<SubscriptionCubit>();
      }

      return null;
    }
  }

  Widget _buildItem(
    BuildContext context, {
    required bool canDownload,
    required bool isLoading,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      leading: Icon(
        icon,
        color: canDownload ? const Color(0xFFFF5500) : Colors.white54,
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        canDownload
            ? 'Available offline'
            : 'Premium required for offline listening',
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
        ),
      ),
      trailing: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFFF5500),
              ),
            )
          : canDownload
              ? const Icon(Icons.chevron_right, color: Colors.white54)
              : Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5500).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFFFF5500).withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Text(
                    'Premium',
                    style: TextStyle(
                      color: Color(0xFFFF5500),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
      onTap: isLoading
          ? null
          : () {
              if (canDownload) {
                context.push(downloadsPath);
                return;
              }

              context.go('/upgrade');
            },
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
    final coverUrl = PlatformUrlUtils.normalizeBackendUrl(
      playlist.coverImageUrl,
    );
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
