import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:soundcloud_clone/core/models/player_state.dart';
import '../models/track.dart';
import '../services/audio_player_service.dart';

class TrackRow extends StatefulWidget {
  final Track track;

  const TrackRow({super.key, required this.track});

  @override
  State<TrackRow> createState() => _TrackRowState();
}

class _TrackRowState extends State<TrackRow> {
  @override
  Widget build(BuildContext context) {
    final player = GetIt.I<AudioPlayerService>();

    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;

        final isPlaying = state?.currentTrackId == widget.track.id;

        return InkWell(
          onTap: () async {
            await player.play(widget.track.audioUrl, widget.track.id);
          },
          splashColor: Colors.white10,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.grey[800],
                    image: widget.track.artworkUrl != null
                        ? DecorationImage(
                            image: NetworkImage(widget.track.artworkUrl!),
                            fit: BoxFit.cover,
                            onError: (_, __) {},
                          )
                        : null,
                  ),
                  child: widget.track.artworkUrl == null
                      ? const Icon(Icons.music_note, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.track.title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isPlaying ? Colors.white : Colors.white,
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
                          widget.track.artist,
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
                  icon: const Icon(Icons.more_vert, color: Color(0xFF666666)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          ListTile(
            title: Text('Like', style: TextStyle(color: Colors.white)),
          ),
          ListTile(
            title:
                Text('Add to playlist', style: TextStyle(color: Colors.white)),
          ),
          ListTile(
            title: Text('Go to artist', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
