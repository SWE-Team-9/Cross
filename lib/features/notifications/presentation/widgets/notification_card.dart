import 'package:flutter/material.dart';

import '../../domain/entities/notification_entity.dart';

class NotificationCard extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('notification_${notification.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Theme.of(context).colorScheme.error,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: notification.isRead
              ? Colors.transparent
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ActorAvatarWithTypeBadge(notification: notification),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: notification.isRead
                                ? FontWeight.w400
                                : FontWeight.w600,
                          ),
                    ),
                    if (_shouldShowTrackName(notification)) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Track: ${notification.trackName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFFB3B3B3),
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      _relativeTime(notification.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFB3B3B3),
                          fontWeight: FontWeight.w500,
                        ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  bool _shouldShowTrackName(NotificationEntity notification) {
    if (notification.trackName.trim().isEmpty) return false;
    return switch (notification.type) {
      NotificationType.like ||
      NotificationType.comment ||
      NotificationType.repost => true,
      _ => false,
    };
  }
}

class _ActorAvatarWithTypeBadge extends StatelessWidget {
  final NotificationEntity notification;

  const _ActorAvatarWithTypeBadge({required this.notification});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = notification.actorAvatarUrl.trim();
    final displayLabel = _initials(notification);

    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF2A2A2A),
            backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl.isEmpty
                ? Text(
                    displayLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: _NotificationTypeIcon(type: notification.type),
          ),
        ],
      ),
    );
  }

  String _initials(NotificationEntity notification) {
    final source = notification.actorDisplayName.trim().isNotEmpty
        ? notification.actorDisplayName.trim()
        : notification.actorHandle.trim();

    if (source.isEmpty) return '?';

    final clean = source.startsWith('@') ? source.substring(1) : source;
    final parts = clean.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return clean[0].toUpperCase();

    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }

    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class _NotificationTypeIcon extends StatelessWidget {
  final NotificationType type;

  const _NotificationTypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = switch (type) {
      NotificationType.like => (Icons.favorite_rounded, Colors.pinkAccent),
      NotificationType.comment => (Icons.chat_bubble_rounded, Colors.teal),
      NotificationType.follow => (Icons.person_add_alt_1_rounded, Colors.blue),
      NotificationType.repost => (Icons.repeat_rounded, Colors.green),
      NotificationType.unknown => (Icons.notifications_rounded, Colors.orange),
    };

    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF111111), width: 1.5),
      ),
      child: Icon(icon, size: 10, color: Colors.white),
    );
  }
}
