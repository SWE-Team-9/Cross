// coverage:ignore-file
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundcloud_clone/core/di/injector.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/models/player_state.dart';
import 'package:soundcloud_clone/core/widgets/track_options_sheet.dart';
import 'package:soundcloud_clone/features/comments/presentation/bloc/comments_cubit.dart';
import 'package:soundcloud_clone/features/comments/presentation/pages/track_comments_page.dart';
import 'package:soundcloud_clone/features/interactions/presentation/bloc/track_interaction_cubit.dart';
import 'package:soundcloud_clone/features/interactions/presentation/bloc/track_interaction_state.dart';
import 'package:soundcloud_clone/features/playback/domain/usecases/get_track_detail_use_case.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_ui_state.dart';
import 'package:soundcloud_clone/features/profile/presentation/routes/profile_routes.dart';

class TrackRow extends StatelessWidget {
  final Track track;
  final List<Track>? queue;
  final bool showLikesCount;
  final String source; // ✅ NEW

  const TrackRow({
    super.key,
    required this.track,
    this.queue,
    this.showLikesCount = false,
    this.source = "unknown", // ✅ DEFAULT
  });

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      PlayerCubit? playerCubit;
      try {
        playerCubit = context.read<PlayerCubit>();
      } catch (_) {
        playerCubit = null;
      }

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
            status: PlayerStatus.idle, position: Duration.zero),
      );
      return buildForState(defaultState);
    });
  }

  Future<void> _playTrack(BuildContext context) async {
    final playerCubit = context.read<PlayerCubit>();
    final tracks = queue ?? [track];
    final index = tracks.indexWhere((t) => t.id == track.id);
    final safeIndex = index >= 0 ? index : 0;
    final selectedTrack = tracks[safeIndex];

    if (selectedTrack.audioUrl.trim().isNotEmpty) {
      await playerCubit.playFromContext(
        tracks: tracks,
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

    await playerCubit.playFromContext(
      tracks: [detail.toPlaybackTrack()],
      startIndex: 0,
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
