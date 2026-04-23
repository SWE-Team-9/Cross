import 'package:flutter/material.dart';

import '../../../../core/utils/platform_url_utils.dart';
import '../../domain/entities/shared_playlist_entity.dart';
import '../messaging_theme.dart';

class MessagePlaylistPreviewCard extends StatelessWidget {
  final SharedPlaylistEntity playlist;
  final VoidCallback? onTap;
  final bool isMine;

  const MessagePlaylistPreviewCard({
    super.key,
    required this.playlist,
    this.onTap,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    final artworkUrl =
        PlatformUrlUtils.normalizeBackendUrl(playlist.artworkUrl);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMine ? MessagingTheme.accentSoft : MessagingTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMine ? const Color(0x55FF5500) : MessagingTheme.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
                image: artworkUrl != null
                    ? DecorationImage(
                        image: NetworkImage(artworkUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: artworkUrl == null
                  ? const Icon(
                      Icons.queue_music,
                      color: Colors.white70,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Playlist',
                    style: TextStyle(
                      color: MessagingTheme.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    playlist.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: MessagingTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${playlist.tracksCount} tracks',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: MessagingTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}