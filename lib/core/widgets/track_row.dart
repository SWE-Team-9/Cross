// coverage:ignore-file
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundcloud_clone/core/di/injector.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/widgets/track_options_sheet.dart';
import 'package:soundcloud_clone/features/comments/presentation/bloc/comments_cubit.dart';
import 'package:soundcloud_clone/features/comments/presentation/pages/track_comments_page.dart';
import 'package:soundcloud_clone/features/interactions/presentation/bloc/track_interaction_cubit.dart';
import 'package:soundcloud_clone/features/interactions/presentation/bloc/track_interaction_state.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_ui_state.dart';
import 'package:soundcloud_clone/features/profile/presentation/routes/profile_routes.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_cubit.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/subscription.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_cubit.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_state.dart';

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
    this.source = "unknown",
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return BlocBuilder<PlayerCubit, PlayerUIState>(
          builder: (context, state) {
            final isCurrentTrack = state.currentTrack?.id == track.id;
            final isPlaying = isCurrentTrack && state.isPlaying;
            final wasPlayed = state.wasPlayed(track.id);
            final opacity = wasPlayed && !isCurrentTrack ? 0.45 : 1.0;

            return Opacity(
              opacity: opacity,
              child: InkWell(
                onTap: () => _playTrack(context),
                splashColor: Colors.white10,
                highlightColor: Colors.white.withValues(alpha: 0.03),
                child: Container(
                  decoration: BoxDecoration(
                    color: isCurrentTrack
                        ? const Color(0xFFFF5500).withValues(alpha: 0.06)
                        : Colors.transparent,
                    border: isCurrentTrack
                        ? Border(
                            left: BorderSide(
                              color: const Color(0xFFFF5500)
                                  .withValues(alpha: 0.7),
                              width: 2,
                            ),
                          )
                        : null,
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: isCurrentTrack ? 12 : 14,
                      right: 14,
                      top: 8,
                      bottom: 8,
                    ),
                    child: Row(
                      children: [
                        // Artwork
                        Stack(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: const Color(0xFF1E1E1E),
                                image: track.artworkUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(track.artworkUrl!),
                                        fit: BoxFit.cover,
                                        onError: (_, __) {},
                                      )
                                    : null,
                              ),
                              child: track.artworkUrl == null
                                  ? Icon(
                                      Icons.music_note,
                                      color:
                                          Colors.white.withValues(alpha: 0.4),
                                      size: 22,
                                    )
                                  : null,
                            ),
                            if (isPlaying)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    color: Colors.black.withValues(alpha: 0.45),
                                  ),
                                  child: const Icon(
                                    Icons.equalizer,
                                    color: Color(0xFFFF5500),
                                    size: 20,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),

                        // Title + subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.title,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isCurrentTrack
                                      ? Colors.white
                                      : Colors.white,
                                  fontSize: 14,
                                  fontWeight: isCurrentTrack
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              if (isPlaying)
                                Row(
                                  children: [
                                    _WaveformIcon(),
                                    const SizedBox(width: 5),
                                    const Text(
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
                                      ? '${track.artist} · ${track.likesCount} likes'
                                      : track.artist,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.45),
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Actions
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            BlocBuilder<SubscriptionCubit, Subscription?>(
                              builder: (context, sub) {
                                final canDownload = sub?.canDownload ?? false;
                                if (!canDownload) return const SizedBox();

                                return BlocBuilder<OfflineCubit, OfflineState>(
                                  builder: (context, offlineState) {
                                    final offlineCubit =
                                        context.read<OfflineCubit>();
                                    final isDownloaded =
                                        offlineCubit.isDownloaded(track.id);

                                    return _DownloadButton(
                                      isDownloaded: isDownloaded,
                                      onTap: () async {
                                        try {
                                          await offlineCubit.download(track.id);
                                          if (!context.mounted) return;
                                          _showDownloadSnackbar(context, true);
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          if (e
                                              .toString()
                                              .contains('UPGRADE_REQUIRED')) {
                                            Navigator.pushNamed(
                                                context, '/upgrade');
                                          } else {
                                            _showDownloadSnackbar(
                                                context, false);
                                          }
                                        }
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(width: 2),
                            GestureDetector(
                              onTap: () =>
                                  TrackOptionsSheet.show(context, track: track),
                              child: Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.more_vert,
                                  color: Colors.white.withValues(alpha: 0.35),
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDownloadSnackbar(BuildContext context, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            success ? const Color(0xFF1A1A1A) : const Color(0xFF1A1A1A),
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
                success ? Icons.download_done_rounded : Icons.error_outline,
                color: success ? const Color(0xFFFF5500) : Colors.red,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              success ? 'Saved for offline listening' : 'Download failed',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _playTrack(BuildContext context) async {
    final playerCubit = context.read<PlayerCubit>();
    final offlineCubit = context.read<OfflineCubit>();

    final tracks = queue ?? [track];
    final index = tracks.indexWhere((t) => t.id == track.id);
    final safeIndex = index >= 0 ? index : 0;

    // 🔥 inject localPath into tracks
    final updatedTracks = tracks.map((t) {
      if (offlineCubit.isDownloaded(t.id)) {
        return t.copyWith(
          localPath: offlineCubit.getPath(t.id),
        );
      }
      return t;
    }).toList();

    await playerCubit.playFromContext(
      tracks: updatedTracks,
      startIndex: safeIndex,
      source: source,
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

// ── Download Button ──────────────────────────────────────────────────────────
class _DownloadButton extends StatelessWidget {
  final bool isDownloaded;
  final VoidCallback onTap;

  const _DownloadButton({
    required this.isDownloaded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: isDownloaded
              ? const Color(0xFFFF5500).withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDownloaded
                ? const Color(0xFFFF5500).withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
        child: Icon(
          isDownloaded
              ? Icons.download_done_rounded
              : Icons.arrow_downward_rounded,
          color: isDownloaded
              ? const Color(0xFFFF5500)
              : Colors.white.withValues(alpha: 0.5),
          size: 15,
        ),
      ),
    );
  }
}

// ── Animated waveform bars ───────────────────────────────────────────────────
class _WaveformIcon extends StatefulWidget {
  @override
  State<_WaveformIcon> createState() => _WaveformIconState();
}

class _WaveformIconState extends State<_WaveformIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final v = _ctrl.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _bar(4 + 6 * v),
            const SizedBox(width: 2),
            _bar(10 - 6 * v),
            const SizedBox(width: 2),
            _bar(6 + 4 * v),
            const SizedBox(width: 2),
            _bar(10 - 4 * v),
          ],
        );
      },
    );
  }

  Widget _bar(double h) => Container(
        width: 2.5,
        height: h,
        decoration: BoxDecoration(
          color: const Color(0xFFFF5500),
          borderRadius: BorderRadius.circular(2),
        ),
      );
}
