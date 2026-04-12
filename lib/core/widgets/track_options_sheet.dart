// core/widgets/track_options_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundcloud_clone/app/app.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/playback_cubit.dart';

import '../../features/playback/presentation/widgets/add_to_playlist_sheet.dart';

class TrackOptionsSheet extends StatelessWidget {
  final Track track;
  final ScrollController scrollController;

  const TrackOptionsSheet._({
    required this.track,
    required this.scrollController,
  });

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
      builder: (_) => BlocProvider.value(
        value: context.read<PlaybackCubit>(),
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
          ),
        ),
      ),
    ).whenComplete(() {
      isTrackSheetOpen.value = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Handle ────────────────────────────────────────────────────
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // ── Track header ──────────────────────────────────────────────
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
                    ? const Icon(Icons.music_note,
                        color: Colors.white54, size: 24)
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

        // ── Share row ─────────────────────────────────────────────────
        const SizedBox(height: 16),
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _ShareItem(icon: Icons.send_outlined, label: 'Message'),
              _ShareItem(icon: Icons.copy_outlined, label: 'Copy Link'),
              _ShareItem(icon: Icons.share_outlined, label: 'WhatsApp'),
              _ShareItem(icon: Icons.camera_alt_outlined, label: 'Status'),
              _ShareItem(icon: Icons.headphones_outlined, label: 'Audio'),
            ],
          ),
        ),

        const Divider(color: Colors.white12, height: 1),

        // ── Action list ───────────────────────────────────────────────
        Expanded(
          child: ListView(
            controller: scrollController,
            children: [
              _OptionTile(
                icon: Icons.favorite_border,
                label: 'Like',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    _snackBar('Liked "${track.title}"'),
                  );
                  // TODO: wire to InteractionsCubit.likeTrack(track.id)
                },
              ),

              _OptionTile(
                icon: Icons.playlist_play,
                label: 'Play Next',
                onTap: () {
                  context.read<PlaybackCubit>().addPlayNext(track);
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
                  context.read<PlaybackCubit>().addPlayLast(track);
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
                icon: Icons.radio,
                label: 'Start station',
                onTap: () => Navigator.pop(context),
              ),

              const Divider(color: Colors.white12, height: 1),

              _OptionTile(
                icon: Icons.person_outline,
                label: 'Go to artist profile',
                onTap: () => Navigator.pop(context),
              ),

              _OptionTile(
                icon: Icons.comment_outlined,
                label: 'View comments',
                onTap: () => Navigator.pop(context),
              ),

              _OptionTile(
                icon: Icons.repeat,
                label: 'Repost on SoundCloud',
                onTap: () => Navigator.pop(context),
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

// ── Internal widgets ──────────────────────────────────────────────────────────

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
      dense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }
}

class _ShareItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ShareItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}