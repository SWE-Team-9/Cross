import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundcloud_clone/core/di/injector.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/comments/presentation/bloc/comments_cubit.dart';
import 'package:soundcloud_clone/features/comments/presentation/pages/track_comments_page.dart';
import 'package:soundcloud_clone/features/interactions/presentation/bloc/track_interaction_cubit.dart';
import 'package:soundcloud_clone/features/interactions/presentation/bloc/track_interaction_state.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_ui_state.dart';
import 'package:soundcloud_clone/features/profile/presentation/routes/profile_routes.dart';

class TrackRow extends StatelessWidget {
  final Track track;

  const TrackRow({super.key, required this.track});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return BlocBuilder<PlayerCubit, PlayerUIState>(
          builder: (context, state) {
            final isPlaying =
                state.currentTrack?.id == track.id && state.isPlaying;

            return InkWell(
              onTap: () async {
                final cubit = context.read<PlayerCubit>();
                await cubit.play(track);
              },
              splashColor: Colors.white10,
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
                            Row(
                              children: const [
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
                    IconButton(
                      onPressed: () => _openMenu(context),
                      icon: const Icon(
                        Icons.more_vert,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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

  void _openMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      builder: (_) => BlocProvider(
        create: (_) => getIt<TrackInteractionCubit>()..load(track.id),
        child: Builder(
          builder: (bottomSheetContext) {
            return BlocBuilder<TrackInteractionCubit, TrackInteractionState>(
              builder: (context, state) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(
                        state.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
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
                      onTap: () => _openComments(context),
                    ),
                    const ListTile(
                      leading:
                          Icon(Icons.playlist_add, color: Colors.white),
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
                        if (track.handle != null &&
                            track.handle!.isNotEmpty) {
                          ProfileRoutes.goToProfile(context, track.handle!);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Artist profile not available'),
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
                      onTap: () {
                        Navigator.pop(context);
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