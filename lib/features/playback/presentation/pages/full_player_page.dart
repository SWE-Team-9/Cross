import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_ui_state.dart';

import '../widgets/player_controls.dart';
import '../widgets/player_seekbar.dart';
import '../widgets/player_actions.dart';

class FullPlayerPage extends StatelessWidget {
  const FullPlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<PlayerCubit, PlayerUIState>(
        builder: (context, state) {
          final track = state.currentTrack;

          if (track == null) {
            return const Center(
              child: Text(
                "No track selected",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return Stack(
            children: [
              Positioned.fill(
                child: track.artworkUrl != null
                    ? Image.network(
                        track.artworkUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container(color: Colors.black),
              ),
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.person_outline,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    PlayerControls(
                      isPlaying: state.isPlaying,
                      position: state.position,
                      duration: state.duration,
                      onPlayPause: () =>
                          context.read<PlayerCubit>().togglePlayPause(),
                      onSeek: (pos) => context.read<PlayerCubit>().seek(pos),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: PlayerSeekBar(
                        position: state.position,
                        duration: state.duration,
                        onSeek: (pos) => context.read<PlayerCubit>().seek(pos),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Text(
                            track.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            track.artist,
                            style: const TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.white10,
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Drop a comment...",
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                          Icon(Icons.local_fire_department,
                              color: Colors.orange),
                          SizedBox(width: 10),
                          Icon(Icons.emoji_emotions, color: Colors.yellow),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const PlayerActions(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
