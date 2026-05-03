import 'package:flutter/material.dart';

import '../../../../core/utils/platform_url_utils.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_type.dart';
import '../messaging_theme.dart';
import 'unread_badge.dart';

class ConversationTile extends StatelessWidget {
  final ConversationEntity conversation;
  final VoidCallback onTap;
  final VoidCallback? onMorePressed;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
    this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = PlatformUrlUtils.normalizeBackendUrl(
        conversation.participant.avatarUrl);

    // Determines if there are unread messages to dynamically highlight details
    final hasUnread = conversation.unreadCount > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                foregroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: Text(
                  conversation.participant.displayName.isNotEmpty
                      ? conversation.participant.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Name and Message details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      conversation.participant.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${conversation.participant.handle}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _lastMessageText(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasUnread 
                            ? Colors.white 
                            : Colors.white.withValues(alpha: 0.55),
                        fontSize: 13,
                        fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Meta info: Timestamp, Unread Badge, Action Button
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (conversation.lastMessage != null)
                    Text(
                      _formatTime(conversation.lastMessage!.createdAt.toLocal()),
                      style: TextStyle(
                        color: hasUnread 
                            ? MessagingTheme.accent 
                            : Colors.white.withValues(alpha: 0.35),
                        fontSize: 11,
                        fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      UnreadBadge(count: conversation.unreadCount),
                      if (conversation.unreadCount > 0) const SizedBox(width: 6),
                      IconButton(
                        tooltip: 'Conversation actions',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        onPressed: onMorePressed,
                        icon: Icon(
                          Icons.more_vert,
                          color: Colors.white.withValues(alpha: 0.4),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
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