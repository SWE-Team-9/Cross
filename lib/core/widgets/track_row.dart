import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/widgets/track_options_sheet.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/playback_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_ui_state.dart';
import 'package:soundcloud_clone/features/profile/presentation/routes/profile_routes.dart';

class TrackRow extends StatelessWidget {
  final Track track;
  final List<Track>? queue;

  const TrackRow({
    super.key,
    required this.track,
    this.queue,
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

            // ← opacity أقل للأغاني اللي اتشغلت زي SoundCloud
            final opacity = wasPlayed && !isCurrentTrack ? 0.45 : 1.0;

            return Opacity(
              opacity: opacity,
              child: InkWell(
                onTap: () async {
                  final playerCubit = context.read<PlayerCubit>();
                  final playbackCubit = context.read<PlaybackCubit>();

                  final tracks = queue ?? [track];
                  final index = tracks.indexWhere((t) => t.id == track.id);
                  final tracksFromHere =
                      index >= 0 ? tracks.sublist(index) : [track];

                  await playbackCubit.playTrack(track, tracksFromHere);
                  await playerCubit.play(track);
                },
                splashColor: Colors.white10,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      // Artwork
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

                      // Track info
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
                                track.artist,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF999999),
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),

                      // More options
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
            );
          },
        );
      },
    );
  }

  void openMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
            leading: Icon(Icons.favorite_border, color: Colors.white),
            title: Text('Like', style: TextStyle(color: Colors.white)),
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
                ProfileRoutes.goToProfile(context, track.handle!);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Artist profile not available'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              Navigator.pop(context);
            },
          ),
          const Divider(color: Color(0xFF1F1F1F), height: 1),
          ListTile(
            leading: const Icon(Icons.report, color: Colors.red),
            title: const Text(
              'Report',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}