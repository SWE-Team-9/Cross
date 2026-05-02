import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:soundcloud_clone/core/di/injector.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/notifiers/overlay_notifiers.dart';
import 'package:soundcloud_clone/features/comments/presentation/bloc/comments_cubit.dart';
import 'package:soundcloud_clone/features/comments/presentation/pages/track_comments_page.dart';
import 'package:soundcloud_clone/features/interactions/presentation/bloc/track_interaction_cubit.dart';
import 'package:soundcloud_clone/features/interactions/presentation/bloc/track_interaction_state.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/profile/presentation/routes/profile_routes.dart';

import '../../features/playback/presentation/widgets/add_to_playlist_sheet.dart';

class TrackOptionsSheet extends StatelessWidget {
  final Track track;
  final ScrollController scrollController;
  final BuildContext parentContext;

  const TrackOptionsSheet._({
    required this.track,
    required this.scrollController,
    required this.parentContext,
  });

  // ── URL builder ────────────────────────────────────────────────────────────
  static String _trackUrl(Track t) {
  debugPrint('handle: ${t.handle}, slug: ${t.slug}');
  if (t.handle != null && t.slug != null) {
    return 'https://dev.iqa3.tech/${t.handle}/${t.slug}';
  }
  return 'https://dev.iqa3.tech/track/${t.id}';
}

  static Future<void> show(BuildContext context, {required Track track}) {
    isTrackSheetOpen.value = true;

    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => getIt<TrackInteractionCubit>()
              ..load(
                trackId: track.id,
                likesCount: track.likesCount,
                repostsCount: track.repostsCount,
              ),
          ),
        ],
        child: DraggableScrollableSheet(
          initialChildSize: 1.0,
          minChildSize: 0.4,
          maxChildSize: 1.0,
          expand: false,
          snap: true,
          snapSizes: const [0.65, 1.0],
          builder: (_, scrollController) => TrackOptionsSheet._(
            track: track,
            scrollController: scrollController,
            parentContext: context,
          ),
        ),
      ),
    ).whenComplete(() {
      isTrackSheetOpen.value = false;
    });
  }

  // ── Copy link to clipboard ─────────────────────────────────────────────────
  Future<void> _copyLink(BuildContext context) async {
    final url = _trackUrl(track);
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Link copied!'),
          backgroundColor: const Color(0xFFFF5500),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ── Native share sheet ─────────────────────────────────────────────────────
Future<void> _shareTrack(BuildContext context) async {
  Navigator.pop(context);
  final url = _trackUrl(track);
  final artistHandle = track.handle ?? track.artist;

  final text = 'Check out "${track.title}" by @$artistHandle\n$url';

  await Share.share(text, subject: track.title);
}

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrackInteractionCubit, TrackInteractionState>(
      builder: (context, interactionState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
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
                            size: 24,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          track.artist,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _ShareItem(
                    icon: Icons.send_outlined,
                    label: 'Message',
                    onTap: () => Navigator.pop(context), // TODO: messaging flow
                  ),
                  _ShareItem(
                    icon: Icons.copy_outlined,
                    label: 'Copy Link',
                    onTap: () => _copyLink(context),
                  ),
                  _ShareItem(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    onTap: () => _shareTrack(context),
                  ),
                  _ShareItem(
                    icon: Icons.camera_alt_outlined,
                    label: 'Status',
                    onTap: () => Navigator.pop(context), // TODO
                  ),
                  _ShareItem(
                    icon: Icons.headphones_outlined,
                    label: 'Audio',
                    onTap: () => Navigator.pop(context), // TODO
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  _OptionTile(
                    icon: interactionState.isLiked
                        ? Icons.favorite
                        : Icons.favorite_border,
                    label: interactionState.isLiked ? 'Unlike' : 'Like',
                    onTap: () {
                      context
                          .read<TrackInteractionCubit>()
                          .toggleLike(track.id);
                    },
                  ),
                  _OptionTile(
                    icon: Icons.playlist_play,
                    label: 'Play Next',
                    onTap: () {
                      _addToActivePlayerQueue(playNext: true);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        _snackBar('"${track.title}" will play next'),
                      );
                    },
                  ),
                  _OptionTile(
                    icon: Icons.queue_music,
                    label: 'Play Last',
                    onTap: () {
                      _addToActivePlayerQueue(playNext: false);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        _snackBar('"${track.title}" added to end of queue'),
                      );
                    },
                  ),
                  _OptionTile(
                    icon: Icons.playlist_add,
                    label: 'Add to playlist',
                    onTap: () {
                      Navigator.pop(context);
                      AddToPlaylistSheet.show(context, track: track);
                    },
                  ),
                  _OptionTile(
                    icon: interactionState.isReposted
                        ? Icons.repeat
                        : Icons.repeat_outlined,
                    label:
                        interactionState.isReposted ? 'Undo repost' : 'Repost',
                    onTap: () {
                      context
                          .read<TrackInteractionCubit>()
                          .toggleRepost(track.id);
                    },
                  ),
                  _OptionTile(
                    icon: Icons.radio,
                    label: 'Start station',
                    onTap: () => Navigator.pop(context),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  _OptionTile(
                    icon: Icons.person_outline,
                    label: 'Go to artist profile',
                    onTap: () {
                      Navigator.pop(context);

                      if (track.handle != null && track.handle!.isNotEmpty) {
                        ProfileRoutes.goToProfile(parentContext, track.handle!);
                      } else {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(
                            content: Text('Artist profile not available'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                  _OptionTile(
                    icon: Icons.comment_outlined,
                    label: 'View comments',
                    onTap: () {
                      Navigator.pop(context);

                      Navigator.push(
                        parentContext,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider(
                            create: (_) =>
                                getIt<CommentsCubit>()..load(track.id),
                            child: TrackCommentsPage(trackId: track.id),
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  _OptionTile(
                    icon: Icons.flag_outlined,
                    label: 'Report',
                    onTap: () => Navigator.pop(context),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _addToActivePlayerQueue({required bool playNext}) {
    try {
      final playerCubit = parentContext.read<PlayerCubit>();
      if (playNext) {
        unawaited(playerCubit.addPlayNext(track));
      } else {
        unawaited(playerCubit.addPlayLast(track));
      }
      return;
    } catch (_) {}

    if (!getIt.isRegistered<PlayerCubit>()) return;

    final playerCubit = getIt<PlayerCubit>();
    if (playNext) {
      unawaited(playerCubit.addPlayNext(track));
    } else {
      unawaited(playerCubit.addPlayLast(track));
    }
  }

  SnackBar _snackBar(String message) {
    return SnackBar(
      backgroundColor: const Color(0xFF333333),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: const Duration(seconds: 2),
      content: Text(message, style: const TextStyle(color: Colors.white)),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70, size: 22),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }
}

class _ShareItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShareItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[850],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}