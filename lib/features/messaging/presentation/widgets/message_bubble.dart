import 'package:flutter/material.dart';

import '../../domain/entities/message_entity.dart';
import '../../domain/entities/message_type.dart';
import '../messaging_theme.dart';
import 'message_playlist_preview_card.dart';
import 'message_track_preview_card.dart';

class MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMine;
  final VoidCallback? onDelete;
  final VoidCallback? onTrackTap;
  final VoidCallback? onPlaylistTap;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.onDelete,
    this.onTrackTap,
    this.onPlaylistTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress:
            isMine && onDelete != null ? () => _showDeleteSheet(context) : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 310),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isMine ? MessagingTheme.accent : MessagingTheme.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMine ? 18 : 6),
                bottomRight: Radius.circular(isMine ? 6 : 18),
              ),
              border: Border.all(
                color: isMine ? const Color(0x66FFB27A) : MessagingTheme.border,
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if ((message.text ?? '').trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      message.text!.trim(),
                      style: TextStyle(
                        color:
                            isMine ? Colors.white : MessagingTheme.textPrimary,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ),
                if (message.type == MessageType.trackShare &&
                    message.sharedTrack != null)
                  MessageTrackPreviewCard(
                    track: message.sharedTrack!,
                    isMine: isMine,
                    onTap: onTrackTap,
                  ),
                if (message.type == MessageType.playlistShare &&
                    message.sharedPlaylist != null)
                  MessagePlaylistPreviewCard(
                    playlist: message.sharedPlaylist!,
                    isMine: isMine,
                    onTap: onPlaylistTap,
                  ),
                const SizedBox(height: 6),
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    color: isMine ? Colors.white70 : MessagingTheme.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MessagingTheme.surfaceAlt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SafeArea(
          child: ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
            title: const Text(
              'Delete message',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              onDelete?.call();
            },
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}
