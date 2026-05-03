import 'dart:ui';
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
    required this.message,
    required this.isMine,
    this.onDelete,
    this.onTrackTap,
    this.onPlaylistTap,
  });

  @override
  Widget build(BuildContext context) {
    final showTimestamp = message.createdAt.year > 2000;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress:
            isMine && onDelete != null ? () => _showDeleteSheet(context) : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMine ? 20 : 4),
                bottomRight: Radius.circular(isMine ? 4 : 20),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMine 
                        ? MessagingTheme.accent.withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMine ? 20 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 20),
                    ),
                    border: Border.all(
                      color: isMine 
                          ? Colors.white.withValues(alpha: 0.2) 
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      if (message.isDeleted)
                        Text(
                          'Message deleted',
                          style: TextStyle(
                            color: isMine ? Colors.white70 : Colors.white.withValues(alpha: 0.3),
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else ...[
                        if ((message.text ?? '').trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              message.text!.trim(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (message.type == MessageType.trackShare &&
                            message.sharedTrack != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: MessageTrackPreviewCard(
                              track: message.sharedTrack!,
                              isMine: isMine,
                              onTap: onTrackTap,
                            ),
                          ),
                        if (message.type == MessageType.playlistShare &&
                            message.sharedPlaylist != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: MessagePlaylistPreviewCard(
                              playlist: message.sharedPlaylist!,
                              isMine: isMine,
                              onTap: onPlaylistTap,
                            ),
                          ),
                      ],
                      if (showTimestamp) ...[
                        const SizedBox(height: 6),
                        Text(
                          _formatTime(message.createdAt.toLocal()),
                          style: TextStyle(
                            color: isMine 
                                ? Colors.white.withValues(alpha: 0.7) 
                                : Colors.white.withValues(alpha: 0.35),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (_) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      title: Text(
                        message.isDeleted ? 'Delete completely' : 'Delete Message',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        onDelete?.call();
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
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