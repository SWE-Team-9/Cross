// coverage:ignore-file
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:soundcloud_clone/core/di/injector.dart';
import 'package:soundcloud_clone/core/models/player_state.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/widgets/track_options_sheet.dart';
import 'package:soundcloud_clone/features/comments/presentation/bloc/comments_cubit.dart';
import 'package:soundcloud_clone/features/comments/presentation/pages/track_comments_page.dart';
import 'package:soundcloud_clone/features/interactions/presentation/bloc/track_interaction_cubit.dart';
import 'package:soundcloud_clone/features/interactions/presentation/bloc/track_interaction_state.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_cubit.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_state.dart';
import 'package:soundcloud_clone/features/playback/domain/usecases/get_track_detail_use_case.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_ui_state.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_cubit.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_state.dart';
import 'package:soundcloud_clone/features/profile/presentation/routes/profile_routes.dart';
import 'package:soundcloud_clone/features/recently_played/presentation/bloc/recently_played_cubit.dart';

enum _DownloadSnack { saved, alreadySaved, failed, upgradeRequired }

class TrackRow extends StatelessWidget {
  final Track track;
  final List<Track>? queue;
  final bool showLikesCount;
  final String source;

  const TrackRow({
    super.key,
    required this.track,
    this.queue,
    this.showLikesCount = false,
    this.source = 'unknown',
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final playerCubit = _lookupCubit<PlayerCubit>(context);

        Widget buildForState(PlayerUIState state) {
          final isCurrentTrack = state.currentTrack?.id == track.id;
          final isPlaying = isCurrentTrack && state.isPlaying;
          final wasPlayed = state.wasPlayed(track.id);
          final opacity = wasPlayed && !isCurrentTrack ? 0.45 : 1.0;

          return Opacity(
            opacity: opacity,
            child: InkWell(
              onTap: () => _playTrack(context),
              splashColor: Colors.white10,
              child: Container(
                color: isCurrentTrack
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.grey[800],
                          image: track.artworkUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(track.artworkUrl!),
                                  fit: BoxFit.cover,
                                  onError: (_, __) {},
                                )
                              : null,
                        ),
                        child: track.artworkUrl == null
                            ? const Icon(Icons.music_note, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.title,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            if (isPlaying)
                              const Row(
                                children: [
                                  Icon(
                                    Icons.equalizer,
                                    color: Color(0xFFFF5500),
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Now Playing',
                                    style: TextStyle(
                                      color: Color(0xFFFF5500),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Text(
                                showLikesCount
                                    ? '${track.artist} - ${track.likesCount} likes'
                                    : track.artist,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF999999),
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      _buildDownloadAction(context),
                      IconButton(
                        onPressed: () =>
                            TrackOptionsSheet.show(context, track: track),
                        icon: const Icon(
                          Icons.more_vert,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        if (playerCubit != null) {
          return BlocBuilder<PlayerCubit, PlayerUIState>(
            bloc: playerCubit,
            builder: (context, state) => buildForState(state),
          );
        }

        final defaultState = PlayerUIState(
          playerState: const PlayerState(
            status: PlayerStatus.idle,
            position: Duration.zero,
          ),
        );

        return buildForState(defaultState);
      },
    );
  }

  Future<void> _playTrack(BuildContext context) async {
    final playerCubit = _lookupCubit<PlayerCubit>(context);

    if (playerCubit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Playback is not available right now')),
      );
      return;
    }

    final offlineCubit = _lookupCubit<OfflineCubit>(context);
    final tracks = queue ?? [track];
    final playableTracks = _withOfflinePaths(tracks, offlineCubit);
    final index = playableTracks.indexWhere((item) => item.id == track.id);
    final safeIndex = index >= 0 ? index : 0;
    final selectedTrack = playableTracks[safeIndex];

    if (selectedTrack.audioUrl.trim().isNotEmpty ||
        (selectedTrack.localPath != null &&
            selectedTrack.localPath!.trim().isNotEmpty)) {
      if (getIt.isRegistered<RecentlyPlayedCubit>()) {
        getIt<RecentlyPlayedCubit>().addTrack(selectedTrack);
      }

      await playerCubit.playFromContext(
        tracks: playableTracks,
        startIndex: safeIndex,
        source: source,
      );

      return;
    }

    if (!getIt.isRegistered<GetTrackDetailUseCase>()) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Playback is not available right now')),
      );
      return;
    }

    final result = await getIt<GetTrackDetailUseCase>()(selectedTrack.id);
    if (!context.mounted) return;

    final detail = result.detail;
    if (result.failure != null || detail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.failure?.message ?? 'Failed to load track for playback',
          ),
        ),
      );
      return;
    }

    final resolvedTrack =
        _withOfflinePath(detail.toPlaybackTrack(), offlineCubit);
    final resolvedQueue = List<Track>.from(playableTracks);
    resolvedQueue[safeIndex] = resolvedTrack;

    if (getIt.isRegistered<RecentlyPlayedCubit>()) {
      getIt<RecentlyPlayedCubit>().addTrack(resolvedTrack);
    }

    await playerCubit.playFromContext(
      tracks: resolvedQueue,
      startIndex: safeIndex,
      source: source,
    );
  }

  Widget _buildDownloadAction(BuildContext context) {
    final subscriptionCubit = _lookupCubit<SubscriptionCubit>(context);
    final offlineCubit = _lookupCubit<OfflineCubit>(context);

    if (subscriptionCubit == null || offlineCubit == null) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<SubscriptionCubit, SubscriptionState>(
      bloc: subscriptionCubit,
      builder: (context, subscriptionState) {
        if (subscriptionState.isInitial || subscriptionState.isLoading) {
          return const SizedBox.shrink();
        }

        final canDownload = subscriptionState.subscription.canDownload;

        if (!canDownload) {
          return _DownloadButton(
            isDownloaded: false,
            isLocked: true,
            onTap: () {
              _showDownloadSnackbar(context, _DownloadSnack.upgradeRequired);
              _openUpgradePage(context);
            },
          );
        }

        return BlocBuilder<OfflineCubit, OfflineState>(
          bloc: offlineCubit,
          builder: (context, offlineState) {
            final isDownloaded = offlineCubit.isDownloaded(track.id);

            return _DownloadButton(
              isDownloaded: isDownloaded,
              onTap: () async {
                if (isDownloaded) {
                  _showDownloadSnackbar(context, _DownloadSnack.alreadySaved);
                  return;
                }

                try {
                  await offlineCubit.downloadTrack(track);

                  if (!context.mounted) return;
                  _showDownloadSnackbar(context, _DownloadSnack.saved);
                } catch (error) {
                  if (!context.mounted) return;

                  if (_isUpgradeRequired(error)) {
                    _showDownloadSnackbar(
                      context,
                      _DownloadSnack.upgradeRequired,
                    );
                    _openUpgradePage(context);
                    return;
                  }

                  _showDownloadSnackbar(context, _DownloadSnack.failed);
                }
              },
            );
          },
        );
      },
    );
  }

  List<Track> _withOfflinePaths(
      List<Track> tracks, OfflineCubit? offlineCubit) {
    if (offlineCubit == null) return tracks;
    return tracks.map((item) => _withOfflinePath(item, offlineCubit)).toList();
  }

  Track _withOfflinePath(Track track, OfflineCubit? offlineCubit) {
    if (offlineCubit == null || !offlineCubit.isDownloaded(track.id)) {
      return track;
    }
    final localPath = offlineCubit.getPath(track.id);
    if (localPath == null || localPath.trim().isEmpty) {
      return track;
    }

    return track.copyWith(localPath: localPath);
  }

  T? _lookupCubit<T extends Object>(BuildContext context) {
    try {
      return context.read<T>();
    } catch (_) {
      if (getIt.isRegistered<T>()) return getIt<T>();
      return null;
    }
  }

  bool _isUpgradeRequired(Object error) {
    final text = error.toString().toUpperCase();

    return text.contains('UPGRADE_REQUIRED') ||
        text.contains('PREMIUM') ||
        text.contains('SUBSCRIPTION') ||
        text.contains('403') ||
        text.contains('401');
  }

  void _openUpgradePage(BuildContext context) {
    try {
      context.push('/upgrade');
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upgrade required for offline downloads')),
      );
    }
  }

  void _showDownloadSnackbar(BuildContext context, _DownloadSnack snack) {
    final success = snack == _DownloadSnack.saved ||
        snack == _DownloadSnack.alreadySaved ||
        snack == _DownloadSnack.upgradeRequired;

    final message = switch (snack) {
      _DownloadSnack.saved => 'Saved for offline listening',
      _DownloadSnack.alreadySaved => 'Music already downloaded',
      _DownloadSnack.failed => 'Download failed',
      _DownloadSnack.upgradeRequired =>
        'Upgrade required for offline downloads',
    };

    final icon = switch (snack) {
      _DownloadSnack.saved => Icons.download_done_rounded,
      _DownloadSnack.alreadySaved => Icons.download_done_rounded,
      _DownloadSnack.failed => Icons.error_outline,
      _DownloadSnack.upgradeRequired => Icons.workspace_premium_rounded,
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: success
                ? const Color(0xFFFF5500).withValues(alpha: 0.4)
                : Colors.red.withValues(alpha: 0.4),
            width: 0.5,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: success
                    ? const Color(0xFFFF5500).withValues(alpha: 0.15)
                    : Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: success ? const Color(0xFFFF5500) : Colors.red,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openComments(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => getIt<CommentsCubit>()..load(track.id),
          child: TrackCommentsPage(trackId: track.id),
        ),
      ),
    );
  }

  void openMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      builder: (_) => BlocProvider(
        create: (_) => getIt<TrackInteractionCubit>()
          ..load(
            trackId: track.id,
            likesCount: track.likesCount,
            repostsCount: track.repostsCount,
          ),
        child: Builder(
          builder: (bottomSheetContext) {
            return BlocBuilder<TrackInteractionCubit, TrackInteractionState>(
              builder: (context, state) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(
                        state.isLiked ? Icons.favorite : Icons.favorite_border,
                        color: Colors.white,
                      ),
                      title: Text(
                        state.isLiked ? 'Unlike' : 'Like',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '${state.likesCount} likes',
                        style: const TextStyle(color: Colors.white54),
                      ),
                      onTap: () async {
                        await bottomSheetContext
                            .read<TrackInteractionCubit>()
                            .toggleLike(track.id);
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.mode_comment_outlined,
                        color: Colors.white,
                      ),
                      title: const Text(
                        'Comments',
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: () => _openComments(bottomSheetContext),
                    ),
                    const ListTile(
                      leading: Icon(Icons.playlist_add, color: Colors.white),
                      title: Text(
                        'Add to playlist',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.person, color: Colors.white),
                      title: const Text(
                        'Go to artist',
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        if (track.handle != null && track.handle!.isNotEmpty) {
                          ProfileRoutes.goToProfile(
                            bottomSheetContext,
                            track.handle!,
                          );
                        } else {
                          ScaffoldMessenger.of(bottomSheetContext).showSnackBar(
                            const SnackBar(
                              content: Text('Artist profile not available'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }

                        Navigator.pop(bottomSheetContext);
                      },
                    ),
                    const Divider(color: Color(0xFF1F1F1F), height: 1),
                    ListTile(
                      leading: const Icon(Icons.report, color: Colors.red),
                      title: const Text(
                        'Report',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () {
                        Navigator.pop(bottomSheetContext);
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _DownloadButton extends StatelessWidget {
  final bool isDownloaded;
  final bool isLocked;
  final VoidCallback onTap;

  const _DownloadButton({
    required this.isDownloaded,
    required this.onTap,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final isHighlighted = isDownloaded || isLocked;

    return Tooltip(
      message: isLocked
          ? 'Upgrade for offline downloads'
          : isDownloaded
              ? 'Downloaded'
              : 'Download for offline listening',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isHighlighted
                ? const Color(0xFFFF5500).withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isHighlighted
                  ? const Color(0xFFFF5500).withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.15),
              width: 0.5,
            ),
          ),
          child: Icon(
            isLocked
                ? Icons.workspace_premium_rounded
                : isDownloaded
                    ? Icons.download_done_rounded
                    : Icons.arrow_downward_rounded,
            color: isHighlighted
                ? const Color(0xFFFF5500)
                : Colors.white.withValues(alpha: 0.5),
            size: 15,
          ),
        ),
      ),
    );
  }
}
