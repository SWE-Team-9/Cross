import 'package:flutter/material.dart';

import '../../../../core/utils/platform_url_utils.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_type.dart';
import '../messaging_theme.dart';
import 'unread_badge.dart';

class ConversationTile extends StatelessWidget {
  final ConversationEntity conversation;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl =
        PlatformUrlUtils.normalizeBackendUrl(conversation.participant.avatarUrl);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MessagingTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: MessagingTheme.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF262626),
              foregroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: Text(
                conversation.participant.displayName.isNotEmpty
                    ? conversation.participant.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.participant.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: MessagingTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '@${conversation.participant.handle}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: MessagingTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _lastMessageText(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: MessagingTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (conversation.lastMessage != null)
                  Text(
                    _formatTime(conversation.lastMessage!.createdAt),
                    style: const TextStyle(
                      color: MessagingTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                const SizedBox(height: 10),
                UnreadBadge(count: conversation.unreadCount),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _lastMessageText() {
    final lastMessage = conversation.lastMessage;
    if (lastMessage == null) return 'No messages yet';

    switch (lastMessage.type) {
      case MessageType.text:
        return lastMessage.text?.trim().isNotEmpty == true
            ? lastMessage.text!.trim()
            : 'Text message';
      case MessageType.trackShare:
        final title = lastMessage.sharedTrack?.title ?? 'Track';
        return '🎵 $title';
      case MessageType.playlistShare:
        final title = lastMessage.sharedPlaylist?.title ?? 'Playlist';
        return '📚 $title';
      case MessageType.unknown:
        return 'Unsupported message';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}