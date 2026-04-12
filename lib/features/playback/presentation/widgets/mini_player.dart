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
        if (track == null) return const SizedBox.shrink();

        return SafeArea(
          child: GestureDetector(
            onTap: () {
              context.read<PlayerCubit>().openFullPlayer();
              router.push(AppRoutes.player);
            },
            child: Hero(
              tag: _playerHeroTag,
              transitionOnUserGestures: true,
              createRectTween: (begin, end) =>
                  MaterialRectCenterArcTween(begin: begin, end: end),
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Container(
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3A3A),
                      borderRadius: BorderRadius.circular(29),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Play/pause circle button
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: GestureDetector(
                            onTap: () =>
                                context.read<PlayerCubit>().togglePlayPause(),
                            child: Container(
                              width: 46,
                              height: 46,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                state.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.black,
                                size: 26,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Title + artist
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Text(
                                track.artist,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),

                        // Follow
                        GestureDetector(
                          onTap: () {},
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              Icons.person_add_outlined,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ),
                        ),

                        // Like
                        GestureDetector(
                          onTap: () {},
                          child: const Padding(
                            padding: EdgeInsets.only(right: 14),
                            child: Icon(
                              Icons.favorite_border,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
