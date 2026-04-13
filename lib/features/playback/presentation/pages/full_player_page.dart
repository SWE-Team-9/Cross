import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:soundcloud_clone/core/di/injector.dart';
import 'package:soundcloud_clone/features/comments/domain/usecases/get_track_comments_usecase.dart';
import 'package:soundcloud_clone/features/comments/presentation/bloc/comments_cubit.dart';
import 'package:soundcloud_clone/features/comments/presentation/pages/track_comments_page.dart';
import 'package:soundcloud_clone/features/interactions/presentation/bloc/engagement_list_cubit.dart';
import 'package:soundcloud_clone/features/interactions/presentation/bloc/engagement_list_state.dart';
import 'package:soundcloud_clone/features/interactions/presentation/bloc/track_interaction_cubit.dart';
import 'package:soundcloud_clone/features/interactions/presentation/bloc/track_interaction_state.dart';
import 'package:soundcloud_clone/features/interactions/presentation/pages/engagement_list_page.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_ui_state.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/playback_cubit.dart';

import '../widgets/player_actions.dart';
import '../widgets/player_waveform.dart';

class FullPlayerPage extends StatefulWidget {
  const FullPlayerPage({super.key});

  static const String playerHeroTag = 'player_shell_hero';

  @override
  State<FullPlayerPage> createState() => _FullPlayerPageState();
}

class _FullPlayerPageState extends State<FullPlayerPage> {
  late PlayerCubit _playerCubit;
  String? _loadedTrackId;
  int _commentsCount = 0;

  @override
  void initState() {
    super.initState();
    _playerCubit = context.read<PlayerCubit>();
    _playerCubit.openFullPlayer();
  }

  @override
  void dispose() {
    _playerCubit.closeFullPlayer();
    super.dispose();
  }

  Future<void> _loadCommentsCount(String trackId) async {
    try {
      final comments = await getIt<GetTrackCommentsUseCase>()(trackId);
      if (!mounted) return;

      setState(() {
        _commentsCount = comments.length;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _commentsCount = 0;
      });
    }
  }

  Future<void> _openComments(BuildContext context, String trackId) async {
    final result = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => getIt<CommentsCubit>()..load(trackId),
          child: TrackCommentsPage(
            trackId: trackId,
            getCurrentPositionSeconds: () =>
                context.read<PlayerCubit>().state.position.inSeconds,
            onSeekToTimestamp: (seconds) {
              context.read<PlayerCubit>().seek(Duration(seconds: seconds));
            },
          ),
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _commentsCount = result;
      });
    } else {
      await _loadCommentsCount(trackId);
    }
  }

  void _openEngagementList(
    BuildContext context, {
    required String trackId,
    required EngagementListType type,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => getIt<EngagementListCubit>()
            ..load(
              trackId: trackId,
              type: type,
            ),
          child: EngagementListPage(
            trackId: trackId,
            type: type,
          ),
        ),
      ),
    );
  }

  void _showQueue(BuildContext context) {
    final playback = context.read<PlaybackCubit>();
    final queue = playback.state.queue;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        if (queue.isEmpty) {
          return const Center(
            child: Text(
              'Queue is empty',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return Column(
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
            const Text(
              'Up Next',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: queue.length,
                itemBuilder: (context, index) {
                  final track = queue[index];
                  return ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                        image: track.artworkUrl != null
                            ? DecorationImage(
                                image: NetworkImage(track.artworkUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: track.artworkUrl == null
                          ? const Icon(
                              Icons.music_note,
                              color: Colors.white54,
                              size: 20,
                            )
                          : null,
                    ),
                    title: Text(
                      track.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      track.artist,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () {
                      playback.playTrack(track, queue);
                      context.read<PlayerCubit>().play(track);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _syncDisplayedTrackFromPlayback(BuildContext context) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));

    if (!mounted) return;

    final playback = context.read<PlaybackCubit>();
    final nextTrack = playback.state.currentTrack;

    if (nextTrack != null) {
      await context.read<PlayerCubit>().play(nextTrack);

      _ensureTrackDataLoaded(
        context,
        trackId: nextTrack.id,
        likesCount: nextTrack.likesCount,
        repostsCount: nextTrack.repostsCount,
      );
    }
  }

  void _ensureTrackDataLoaded(
    BuildContext context, {
    required String trackId,
    required int likesCount,
    required int repostsCount,
  }) {
    if (_loadedTrackId == trackId) return;

    _loadedTrackId = trackId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _loadedTrackId != trackId) return;

      context.read<TrackInteractionCubit>().load(
            trackId: trackId,
            likesCount: likesCount,
            repostsCount: repostsCount,
          );

      _loadCommentsCount(trackId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final playback = context.read<PlaybackCubit>();

    return Hero(
      tag: FullPlayerPage.playerHeroTag,
      transitionOnUserGestures: true,
      createRectTween: (begin, end) =>
          MaterialRectCenterArcTween(begin: begin, end: end),
      child: Material(
        color: Colors.black,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: BlocBuilder<PlayerCubit, PlayerUIState>(
            builder: (context, state) {
              final track = state.currentTrack;

              if (track == null) {
                return const Center(
                  child: Text(
                    'No track selected',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              _ensureTrackDataLoaded(
                context,
                trackId: track.id,
                likesCount: track.likesCount,
                repostsCount: track.repostsCount,
              );

              return BlocBuilder<TrackInteractionCubit, TrackInteractionState>(
                builder: (context, interactionState) {
                  return Stack(
                    children: [
                      if (track.artworkUrl != null)
                        Positioned.fill(
                          child: Image.network(
                            track.artworkUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: Colors.black),
                            loadingBuilder: (_, child, loading) =>
                                loading == null
                                    ? child
                                    : Container(color: Colors.black),
                          ),
                        ),
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.transparent,
                                Color(0xCC000000),
                                Colors.black,
                              ],
                              stops: [0.0, 0.35, 0.65, 0.85],
                            ),
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 12, 16, 0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          track.title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black54,
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          track.artist,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        GestureDetector(
                                          onTap: () {},
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black45,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.bar_chart,
                                                  color: Colors.white70,
                                                  size: 14,
                                                ),
                                                SizedBox(width: 5),
                                                Text(
                                                  'Behind this track',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      _CircleBtn(
                                        icon: Icons.keyboard_arrow_down,
                                        onTap: () {
                                          context
                                              .read<PlayerCubit>()
                                              .closeFullPlayer();
                                          Navigator.pop(context);
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      _CircleBtn(
                                        icon: Icons.person_add_outlined,
                                        onTap: () {},
                                      ),
                                      const SizedBox(height: 12),
                                      _CircleBtn(
                                        icon: Icons.cast,
                                        onTap: () {},
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: PlayerWaveform(
                                position: state.position,
                                duration: state.duration,
                                onSeek: (pos) =>
                                    context.read<PlayerCubit>().seek(pos),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_format(state.position)} | ${_format(state.duration ?? Duration.zero)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: GestureDetector(
                                onTap: () => _openComments(context, track.id),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black45,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Comment...',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      Text('🔥', style: TextStyle(fontSize: 20)),
                                      SizedBox(width: 10),
                                      Text('👏', style: TextStyle(fontSize: 20)),
                                      SizedBox(width: 10),
                                      Text('🥰', style: TextStyle(fontSize: 20)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.skip_previous,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                  onPressed: () async {
                                    playback.playPrevious();
                                    await _syncDisplayedTrackFromPlayback(context);
                                  },
                                ),
                                const SizedBox(width: 20),
                                GestureDetector(
                                  onTap: () => context
                                      .read<PlayerCubit>()
                                      .togglePlayPause(),
                                  child: Container(
                                    width: 64,
                                    height: 64,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFF5500),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      state.isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      size: 34,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                IconButton(
                                  icon: const Icon(
                                    Icons.skip_next,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                  onPressed: () async {
                                    playback.playNext();
                                    await _syncDisplayedTrackFromPlayback(context);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            PlayerActions(
                              onQueueTap: () => _showQueue(context),
                              onCommentsTap: () => _openComments(context, track.id),
                              onLikesTap: () => _openEngagementList(
                                context,
                                trackId: track.id,
                                type: EngagementListType.likers,
                              ),
                              onRepostsTap: () => _openEngagementList(
                                context,
                                trackId: track.id,
                                type: EngagementListType.reposters,
                              ),
                              onLikeToggle: () => context
                                  .read<TrackInteractionCubit>()
                                  .toggleLike(track.id),
                              onRepostToggle: () => context
                                  .read<TrackInteractionCubit>()
                                  .toggleRepost(track.id),
                              likesCount: interactionState.likesCount,
                              repostsCount: interactionState.repostsCount,
                              commentsCount: _commentsCount,
                              isLiked: interactionState.isLiked,
                              isReposted: interactionState.isReposted,
                              isSubmittingLike:
                                  interactionState.isSubmittingLike,
                              isSubmittingRepost:
                                  interactionState.isSubmittingRepost,
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
