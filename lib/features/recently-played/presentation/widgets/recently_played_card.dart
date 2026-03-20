import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';

class RecentlyPlayedCard extends StatelessWidget {
  final Track track;

  const RecentlyPlayedCard({
    super.key,
    required this.track,
  });

  @override
  Widget build(BuildContext context) {
    final player = GetIt.I<AudioPlayerService>();

    return GestureDetector(
      onTap: () async {
        await player.play(track.audioUrl, track.id);
      },
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artwork
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey[800],
                image: track.artworkUrl != null
                    ? DecorationImage(
                        image: NetworkImage(track.artworkUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: track.artworkUrl == null
                  ? const Icon(Icons.music_note, color: Colors.white)
                  : null,
            ),

            const SizedBox(height: 6),

            // Title
            Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),

            // Artist
            Text(
              track.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF999999),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
