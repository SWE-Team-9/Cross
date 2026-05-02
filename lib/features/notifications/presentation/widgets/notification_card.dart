import 'package:flutter/material.dart';

import 'package:soundcloud_clone/core/di/injector.dart';
import 'package:soundcloud_clone/features/notifications/notifications.dart';
import 'package:soundcloud_clone/features/playback/domain/usecases/get_track_detail_use_case.dart';

class NotificationCard extends StatefulWidget {
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
  State<NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard> {
  Future<String>? _resolvedTitleFuture;

  @override
  void initState() {
    super.initState();
    _resolvedTitleFuture = _shouldResolveTrackTitle(widget.notification)
        ? _fetchTrackTitle(widget.notification.entityId)
        : Future.value('');
  }

  @override
  void didUpdateWidget(covariant NotificationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notification.id != widget.notification.id ||
        oldWidget.notification.entityId != widget.notification.entityId ||
        oldWidget.notification.message != widget.notification.message) {
      _resolvedTitleFuture = _shouldResolveTrackTitle(widget.notification)
          ? _fetchTrackTitle(widget.notification.entityId)
          : Future.value('');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('notification_${widget.notification.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Theme.of(context).colorScheme.error,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          color: widget.notification.isRead
              ? Colors.transparent
              : SoundCloudColors.darkGrey.withAlpha(150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ActorAvatarWithTypeBadge(notification: widget.notification),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<String>(
                      future: _resolvedTitleFuture,
                      builder: (context, snapshot) {
                        final title = snapshot.data?.trim() ?? '';
                        final message = _buildMessageWithTitle(
                          widget.notification.message,
                          title,
                        );

                        return Text(
                          message,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: widget.notification.isRead
                                        ? FontWeight.w400
                                        : FontWeight.w600,
                                  ),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _relativeTime(widget.notification.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFB3B3B3),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              if (!widget.notification.isRead)
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

  bool _shouldResolveTrackTitle(NotificationEntity notification) {
    if (notification.entityId.trim().isEmpty) return false;
    if (notification.trackName.trim().isNotEmpty) return false;

    return switch (notification.type) {
      NotificationType.like ||
      NotificationType.comment ||
      NotificationType.repost =>
        true,
      _ => false,
    };
  }

  Future<String> _fetchTrackTitle(String trackId) async {
    if (!getIt.isRegistered<GetTrackDetailUseCase>()) return '';

    try {
      final result = await getIt<GetTrackDetailUseCase>()(trackId.trim());
      return result.detail?.title.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  String _buildMessageWithTitle(String message, String title) {
    final base = message.trim();
    final track = title.trim();
    if (base.isEmpty || track.isEmpty) return base;
    if (base.toLowerCase().contains(track.toLowerCase())) return base;
    return '$base $track';
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
            backgroundImage:
                avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
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
    final parts =
        clean.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return clean[0].toUpperCase();

    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
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
      NotificationType.message => (Icons.mail_rounded, Colors.purple),
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
