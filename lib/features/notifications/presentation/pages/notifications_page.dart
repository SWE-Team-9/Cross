import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundcloud_clone/core/di/injector.dart';
import 'package:soundcloud_clone/features/comments/presentation/bloc/comments_cubit.dart';
import 'package:soundcloud_clone/features/comments/presentation/pages/track_comments_page.dart';
import 'package:soundcloud_clone/features/messaging/presentation/routes/messaging_routes.dart';
import 'package:soundcloud_clone/features/notifications/domain/entities/notification_entity.dart';
import 'package:soundcloud_clone/features/notifications/domain/entities/notification_preferences_entity.dart';
import 'package:soundcloud_clone/features/profile/presentation/routes/profile_routes.dart';
import 'package:soundcloud_clone/features/notifications/domain/entities/notification_tap_target.dart';
import 'package:soundcloud_clone/features/notifications/domain/usecases/resolve_notification_tap_target_use_case.dart';

import '../bloc/notification_preferences_bloc.dart';
import '../bloc/notifications_bloc.dart';
import '../widgets/notification_card.dart';
import '../widgets/notification_preferences_sheet.dart';

class SoundCloudColors {
  static const orange = Color(0xFFFF5500);
  static const deepBlack = Color.fromARGB(255, 0, 0, 0);
  static const darkGrey = Color(0xFF222222);
  static const lightGrey = Color(0xFF999999);
}

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
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: SoundCloudColors.deepBlack,
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
              fontFamily: 'Inter',
            ),
        appBarTheme: const AppBarTheme(
          backgroundColor: SoundCloudColors.deepBlack,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Inter',
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        dividerTheme: const DividerThemeData(
          color: SoundCloudColors.darkGrey,
          thickness: 1,
        ),
      ),
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: BlocBuilder<NotificationsBloc, NotificationsState>(
          builder: (context, state) {
            return switch (state) {
              NotificationsInitial() => const SizedBox.shrink(),
              NotificationsLoading() => const Center(
                  child: CircularProgressIndicator(
                      color: SoundCloudColors.orange)),
              NotificationsError(message: final msg) =>
                _ErrorView(message: msg),
              NotificationsLoaded() ||
              NotificationsLoadingMore() =>
                _NotificationList(
                  state: state,
                  scrollController: _scrollController,
                ),
              _ => const SizedBox.shrink(),
            };
          },
        ),
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
                    child: const Text(
                      'Mark all read',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: SoundCloudColors.orange,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          },
        ),
        IconButton(
          icon: const Icon(Icons.tune_rounded, color: Colors.white),
          onPressed: () => NotificationPreferencesSheet.show(context),
        ),
      ],
    );
  }
}

class _NotificationList extends StatelessWidget {
  final NotificationsState state;
  final ScrollController scrollController;

  const _NotificationList({
    required this.state,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final notifications = switch (state) {
      NotificationsLoaded(notifications: final n) => n,
      _ => const <NotificationEntity>[],
    };

    final preferences =
        context.watch<NotificationPreferencesBloc>().state.preferences;
    final filteredNotifications = notifications
        .where((notification) => _passesTypeFilter(notification, preferences))
        .toList(growable: false);

    if (filteredNotifications.isEmpty) {
      return const _EmptyView();
    }

    return RefreshIndicator(
      color: SoundCloudColors.orange,
      backgroundColor: SoundCloudColors.darkGrey,
      onRefresh: () async =>
          context.read<NotificationsBloc>().add(const LoadNotifications()),
      child: ListView.separated(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: filteredNotifications.length +
            (state is NotificationsLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == filteredNotifications.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                  child: CircularProgressIndicator(
                      color: SoundCloudColors.orange)),
            );
          }

          final notification = filteredNotifications[index];
          return NotificationCard(
            notification: notification,
            onTap: () async {
              context
                  .read<NotificationsBloc>()
                  .add(MarkNotificationRead(notification.id));
              await _navigateToContent(context, notification);
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

  bool _passesTypeFilter(
    NotificationEntity notification,
    NotificationPreferencesEntity preferences,
  ) {
    return switch (notification.type) {
      NotificationType.like => preferences.likesEnabled,
      NotificationType.comment => preferences.commentsEnabled,
      NotificationType.follow => preferences.followsEnabled,
      NotificationType.repost => preferences.repostsEnabled,
      NotificationType.message => true,
      NotificationType.unknown => true,
    };
  }

  Future<void> _navigateToContent(
    BuildContext context,
    NotificationEntity notification,
  ) async {
    final resolver = getIt<ResolveNotificationTapTargetUseCase>();
    final target = await resolver(notification);
    if (!context.mounted) return;

    switch (target) {
      case NotificationCommentsTapTarget(trackId: final trackId):
        await _openTrackComments(context, trackId);
        return;
      case NotificationConversationTapTarget(conversation: final conversation):
        await MessagingRoutes.goToConversation(context, conversation);
        return;
      case NotificationProfileTapTarget(handle: final handle):
        ProfileRoutes.goToProfile(context, handle);
        return;
      case null:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open this notification')),
        );
    }
  }

  Future<void> _openTrackComments(BuildContext context, String trackId) async {
    if (trackId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open comments right now')),
      );
      return;
    }

    await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => getIt<CommentsCubit>(),
          child: TrackCommentsPage(trackId: trackId),
        ),
      ),
    );
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
          const Icon(
            Icons.notifications_none_rounded,
            size: 100,
            color: SoundCloudColors.darkGrey,
          ),
          const SizedBox(height: 24),
          const Text(
            'No notifications yet',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Likes, comments, and follows will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              color: SoundCloudColors.lightGrey,
              fontSize: 15,
              fontWeight: FontWeight.w400,
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
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 60, color: SoundCloudColors.orange),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: SoundCloudColors.orange,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero),
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                onPressed: () => context
                    .read<NotificationsBloc>()
                    .add(const LoadNotifications()),
                child: const Text('RETRY'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
