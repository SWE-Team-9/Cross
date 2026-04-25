import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:soundcloud_clone/features/notifications/domain/entities/notification_entity.dart';
import 'package:soundcloud_clone/features/profile/presentation/routes/profile_routes.dart';

import '../bloc/notification_preferences_bloc.dart';
import '../bloc/notifications_bloc.dart';
import '../widgets/notification_card.dart';
import '../widgets/notification_preferences_sheet.dart';

/// T5.6 — Notifications Center
/// T5.7 — Notification Read State
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  static const String routeName = '/notifications';

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<NotificationsBloc>().add(const LoadNotifications());
    context.read<NotificationPreferencesBloc>().add(const LoadPreferences());

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<NotificationsBloc>().add(const LoadMoreNotifications());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          // Exhaustive switch for Bloc states
          return switch (state) {
            NotificationsInitial() => const SizedBox.shrink(),
            NotificationsLoading() =>
              const Center(child: CircularProgressIndicator()),
            NotificationsError(message: final msg) => _ErrorView(message: msg),
            // We handle both Loaded and LoadingMore here since they both display the list
            NotificationsLoaded() || NotificationsLoadingMore() => _NotificationList(
                state: state,
                scrollController: _scrollController,
              ),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Notifications'),
      centerTitle: false,
      actions: [
        BlocBuilder<NotificationsBloc, NotificationsState>(
          builder: (context, state) {
            final unreadCount = state is NotificationsLoaded 
                ? state.unreadCount 
                : (state is NotificationsLoadingMore ? state.unreadCount : 0);
            
            return unreadCount > 0
                ? TextButton(
                    onPressed: () => context
                        .read<NotificationsBloc>()
                        .add(const MarkAllNotificationsRead()),
                    child: const Text('Mark all read'),
                  )
                : const SizedBox.shrink();
          },
        ),
        IconButton(
          icon: const Icon(Icons.tune_rounded),
          tooltip: 'Preferences',
          onPressed: () => NotificationPreferencesSheet.show(context),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────

class _NotificationList extends StatelessWidget {
  final NotificationsState state; // Changed to base class to handle both Loaded and LoadingMore
  final ScrollController scrollController;

  const _NotificationList({
    required this.state,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    // Helper to extract notifications from either state
    final notifications = switch (state) {
      NotificationsLoaded(notifications: final n) => n,
      // NotificationsLoadingMore(notifications: final n) => n,
      _ => const <NotificationEntity>[],
    };

    if (notifications.isEmpty) {
      return const _EmptyView();
    }

    return RefreshIndicator(
      onRefresh: () async =>
          context.read<NotificationsBloc>().add(const LoadNotifications()),
      child: ListView.separated(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount:
            notifications.length + (state is NotificationsLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == notifications.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final notification = notifications[index];
          return NotificationCard(
            notification: notification,
            onTap: () {
              context
                  .read<NotificationsBloc>()
                  .add(MarkNotificationRead(notification.id));
              _navigateToContent(context, notification);
            },
            onDelete: () {
              context
                  .read<NotificationsBloc>()
                  .add(DeleteNotification(notification.id));
            },
          );
        },
      ),
    );
  }

  void _navigateToContent(
      BuildContext context, NotificationEntity notification) {
    final entityType = notification.entityType;
    final entityId = notification.entityId;

    if (entityId.isEmpty) return;

    switch (entityType.toLowerCase()) {
      case 'track' || 'comment': // Combined similar cases
        context.push('/track/$entityId');
      case 'user':
        ProfileRoutes.goToProfile(context, entityId);
      default:
        break;
    }
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Likes, comments, and follows will appear here.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context
                .read<NotificationsBloc>()
                .add(const LoadNotifications()),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
