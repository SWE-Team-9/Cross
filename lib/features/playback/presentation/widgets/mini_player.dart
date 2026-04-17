import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_ui_state.dart';

import '../../../../app/router.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  static const String _playerHeroTag = 'player_shell_hero';

  void _showVolumeSheet(BuildContext context, double currentVolume) {
    double localVolume = currentVolume;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Row(
                children: [
                  const Icon(Icons.volume_up, color: Colors.white70),
                  Expanded(
                    child: Slider(
                      value: localVolume,
                      activeColor: const Color(0xFFFF5500),
                      onChanged: (value) {
                        setModalState(() => localVolume = value);
                        context.read<PlayerCubit>().setVolume(value);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerCubit, PlayerUIState>(
      builder: (context, state) {
        final track = state.currentTrack;
        if (track == null) {
          return const SizedBox.shrink();
        }

        final duration = state.duration;
        final double progress =
            (duration != null && duration.inMilliseconds > 0)
                ? (state.position.inMilliseconds / duration.inMilliseconds)
                    .clamp(0.0, 1.0)
                : 0.0;

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
                        // ── Play/pause with progress ring ──────────────
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: GestureDetector(
                            onTap: () =>
                                context.read<PlayerCubit>().togglePlayPause(),
                            child: SizedBox(
                              width: 46,
                              height: 46,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 2.5,
                                    backgroundColor: Colors.white24,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      Color(0xFFFF5500),
                                    ),
                                  ),
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      state.isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      color: Colors.black,
                                      size: 22,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // ── Title + artist ────────────────────────────
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

                        // ── Follow ────────────────────────────────────
                        GestureDetector(
                          onTap: () => _showVolumeSheet(context, state.volume),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              Icons.volume_up_outlined,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ),
                        ),

                        // ── Like ──────────────────────────────────────
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
