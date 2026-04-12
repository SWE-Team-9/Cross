import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_ui_state.dart';
import '../../../../app/router.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  static const String _playerHeroTag = 'player_shell_hero';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerCubit, PlayerUIState>(
      builder: (context, state) {
        final track = state.currentTrack;

        if (track == null) {
          return const SizedBox.shrink();
        }

        return SafeArea(
          child: Builder(
            // 🔥 FIX: gives correct Navigator context
            builder: (innerContext) {
              return GestureDetector(
                onTap: () {
                  router.push(AppRoutes.player);
                },
                child: Hero(
                  tag: _playerHeroTag,
                  transitionOnUserGestures: true,
                  createRectTween: (begin, end) =>
                      MaterialRectCenterArcTween(begin: begin, end: end),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      height: 60, // 🔥 smaller
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[900]?.withValues(alpha: 0.95),
                        borderRadius:
                            BorderRadius.circular(40), // 🔥 pill shape
                      ),
                      child: Row(
                        children: [
                          // ▶️ Play Button
                          _PlayButton(
                            isPlaying: state.isPlaying,
                            position: state.playerState.position,
                            duration: state.playerState.duration,
                          ),

                          const SizedBox(width: 10),

                          // 🎵 Title + Artist
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  track.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13, // 🔥 smaller
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  track.artist,
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 11, // 🔥 smaller
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // 👤
                          IconButton(
                            icon: const Icon(Icons.person_add_alt_1,
                                color: Colors.white, size: 20),
                            onPressed: () {},
                          ),

                          // ❤️
                          IconButton(
                            icon: const Icon(Icons.favorite_border,
                                color: Colors.white, size: 20),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _PlayButton extends StatelessWidget {
  final bool isPlaying;
  final Duration position;
  final Duration? duration;

  const _PlayButton({
    required this.isPlaying,
    required this.position,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlayerCubit>();

    final progress = (duration != null && duration!.inMilliseconds > 0)
        ? position.inMilliseconds / duration!.inMilliseconds
        : 0.0;

    return GestureDetector(
      onTap: () {
        if (isPlaying) {
          cubit.pause();
        } else {
          cubit.resume();
        }
      },
      child: SizedBox(
        width: 40, // 🔥 smaller
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: 2.5,
              backgroundColor: Colors.grey[700],
              valueColor: const AlwaysStoppedAnimation(Colors.orange),
            ),
            Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 22, // 🔥 smaller
            ),
          ],
        ),
      ),
    );
  }
}
