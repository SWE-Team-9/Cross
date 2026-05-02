import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/utils/platform_url_utils.dart';
import 'package:soundcloud_clone/core/widgets/track_row.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_cubit.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_state.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_cubit.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_state.dart';

class DownloadedTracksPage extends StatelessWidget {
  const DownloadedTracksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _DownloadedShell(
      title: 'Downloaded tracks',
      child: _PremiumDownloadGate(
        child: BlocBuilder<OfflineCubit, OfflineState>(
          bloc: GetIt.I<OfflineCubit>(),
          builder: (context, state) {
            final tracks = state.downloadedTrackDetails.values.toList();
            final fallbackTracks = state.downloadedTracks.entries
                .where(
                  (entry) => !state.downloadedTrackDetails.containsKey(
                    entry.key,
                  ),
                )
                .map(
                  (entry) => Track(
                    id: entry.key,
                    title: entry.key,
                    artist: 'Downloaded track',
                    audioUrl: '',
                    localPath: entry.value,
                  ),
                )
                .toList(growable: false);
            final allTracks = <Track>[...tracks, ...fallbackTracks];

            if (allTracks.isEmpty) {
              return const _EmptyDownloads(
                icon: Icons.download_for_offline_outlined,
                message: 'No downloaded tracks yet',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: allTracks.length,
              itemBuilder: (context, index) {
                final track = allTracks[index];

                return TrackRow(
                  track: track,
                  queue: allTracks,
                  source: 'downloaded_tracks',
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class DownloadedPlaylistsPage extends StatelessWidget {
  const DownloadedPlaylistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _DownloadedShell(
      title: 'Downloaded playlists',
      child: _PremiumDownloadGate(
        child: BlocBuilder<OfflineCubit, OfflineState>(
          bloc: GetIt.I<OfflineCubit>(),
          builder: (context, state) {
            final playlists = state.downloadedPlaylists.values.toList();

            if (playlists.isEmpty) {
              return const _EmptyDownloads(
                icon: Icons.queue_music,
                message: 'No downloaded playlists yet',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
              itemCount: playlists.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _DownloadedPlaylistTile(playlist: playlists[index]);
              },
            );
          },
        ),
      ),
    );
  }
}

class _DownloadedShell extends StatelessWidget {
  const _DownloadedShell({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(title),
      ),
      body: child,
    );
  }
}

class _PremiumDownloadGate extends StatelessWidget {
  const _PremiumDownloadGate({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final subscriptionCubit = _subscriptionCubitOf(context);

    if (subscriptionCubit == null) {
      return child;
    }

    return BlocBuilder<SubscriptionCubit, SubscriptionState>(
      bloc: subscriptionCubit,
      builder: (context, state) {
        if (state.isInitial || state.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFF5500),
            ),
          );
        }

        if (!state.subscription.canDownload) {
          return const _PremiumDownloadsLocked();
        }

        return child;
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
}

class _PremiumDownloadsLocked extends StatelessWidget {
  const _PremiumDownloadsLocked();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: const Color(0xFFFF5500).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFFF5500).withValues(alpha: 0.35),
                ),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFFFF5500),
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Offline downloads are premium',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upgrade to save tracks and playlists for offline listening.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.go('/upgrade'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF5500),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
              ),
              icon: const Icon(Icons.workspace_premium_rounded),
              label: const Text('Upgrade'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadedPlaylistTile extends StatelessWidget {
  const _DownloadedPlaylistTile({required this.playlist});

  final PlaylistEntity playlist;

  @override
  Widget build(BuildContext context) {
    final coverUrl = PlatformUrlUtils.normalizeBackendUrl(
      playlist.coverImageUrl,
    );

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 54,
          height: 54,
          color: const Color(0xFF222222),
          child: coverUrl == null
              ? const Icon(Icons.queue_music, color: Colors.white54)
              : Image.network(
                  coverUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.queue_music,
                    color: Colors.white54,
                  ),
                ),
        ),
      ),
      title: Text(
        playlist.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        '${playlist.tracks.length} downloaded tracks',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white54),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: () => context.push(
        '/playlist/${playlist.playlistId}',
        extra: playlist,
      ),
    );
  }
}

class _EmptyDownloads extends StatelessWidget {
  const _EmptyDownloads({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white38, size: 46),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}