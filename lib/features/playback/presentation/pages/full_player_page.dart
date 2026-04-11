import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_ui_state.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/playback_cubit.dart';

import '../widgets/player_actions.dart';
import '../widgets/player_waveform.dart';

class FullPlayerPage extends StatefulWidget {
  const FullPlayerPage({super.key});

  @override
  State<FullPlayerPage> createState() => _FullPlayerPageState();
}

class _FullPlayerPageState extends State<FullPlayerPage> {
  late PlayerCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<PlayerCubit>();
  }

  @override
  void dispose() {
    _cubit.closeFullPlayer();
    super.dispose();
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
            child:
                Text("Queue is empty", style: TextStyle(color: Colors.white70)),
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
            const Text("Up Next",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
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
                          ? const Icon(Icons.music_note,
                              color: Colors.white54, size: 20)
                          : null,
                    ),
                    title: Text(track.title,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                        overflow: TextOverflow.ellipsis),
                    subtitle: Text(track.artist,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                    onTap: () {
                      playback.playTrack(track, queue);
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

  @override
  Widget build(BuildContext context) {
    final playback = context.read<PlaybackCubit>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<PlayerCubit, PlayerUIState>(
        builder: (context, state) {
          final track = state.currentTrack;

          if (track == null) {
            return const Center(
              child: Text("No track selected",
                  style: TextStyle(color: Colors.white)),
            );
          }

          return Stack(
            children: [
              // ── الصورة بتملي الشاشة ───────────────────────────────
              if (track.artworkUrl != null)
                Positioned.fill(
                  child: Image.network(
                    track.artworkUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.black),
                    loadingBuilder: (_, child, loading) => loading == null
                        ? child
                        : Container(color: Colors.black),
                  ),
                ),

              // ── Gradient من تحت بس ────────────────────────────────
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

              // ── المحتوى ──────────────────────────────────────────
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── TOP: عنوان على الشمال، أزرار على اليمين ──────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // العنوان والفنان
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  track.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                          color: Colors.black54, blurRadius: 8),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  track.artist,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 14),
                                ),
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () {},
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black45,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.bar_chart,
                                            color: Colors.white70, size: 14),
                                        SizedBox(width: 5),
                                        Text("Behind this track",
                                            style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // أزرار يمين عمودية
                          Column(
                            children: [
                              _CircleBtn(
                                icon: Icons.keyboard_arrow_down,
                                onTap: () {
                                  context.read<PlayerCubit>().closeFullPlayer();
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

                    // ── WAVEFORM ──────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: PlayerWaveform(
                        position: state.position,
                        duration: state.duration,
                        onSeek: (pos) => context.read<PlayerCubit>().seek(pos),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // الوقت في المنتصف
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_format(state.position)} | ${_format(state.duration ?? Duration.zero)}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── COMMENT BOX ───────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: const [
                            Expanded(
                              child: Text("Comment...",
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 13)),
                            ),
                            Text("🔥", style: TextStyle(fontSize: 20)),
                            SizedBox(width: 10),
                            Text("👏", style: TextStyle(fontSize: 20)),
                            SizedBox(width: 10),
                            Text("🥰", style: TextStyle(fontSize: 20)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── CONTROLS: prev + play/pause + next ────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Previous
                        IconButton(
                          icon: const Icon(Icons.skip_previous,
                              color: Colors.white, size: 36),
                          onPressed: () => playback.playPrevious(),
                        ),
                        const SizedBox(width: 20),

                        // Play/Pause
                        GestureDetector(
                          onTap: () =>
                              context.read<PlayerCubit>().togglePlayPause(),
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF5500),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              state.isPlaying ? Icons.pause : Icons.play_arrow,
                              size: 34,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(width: 20),

                        // Next
                        IconButton(
                          icon: const Icon(Icons.skip_next,
                              color: Colors.white, size: 36),
                          onPressed: () => playback.playNext(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ── ACTIONS ───────────────────────────────────────
                    PlayerActions(
                      onQueueTap: () => _showQueue(context),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }
}

// ── Helper Widget ─────────────────────────────────────────────────────────────
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
        decoration: BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
