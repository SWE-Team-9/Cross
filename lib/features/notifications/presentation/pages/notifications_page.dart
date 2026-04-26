import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundcloud_clone/core/di/injector.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/notifications/domain/entities/notification_entity.dart';
import 'package:soundcloud_clone/features/notifications/domain/entities/notification_preferences_entity.dart';
import 'package:soundcloud_clone/features/playback/domain/usecases/get_track_detail_use_case.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:soundcloud_clone/features/profile/presentation/routes/profile_routes.dart';
import 'package:soundcloud_clone/features/social/data/repositories/social_repo.dart';

import '../bloc/notification_preferences_bloc.dart';
import '../bloc/notifications_bloc.dart';
import '../widgets/notification_card.dart';
import '../widgets/notification_preferences_sheet.dart';

class SoundCloudColors {
  static const orange = Color(0xFFFF5500);
  static const deepBlack = Color(0xFF111111);
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
              NotificationsLoading() =>
                const Center(child: CircularProgressIndicator(color: SoundCloudColors.orange)),
              NotificationsError(message: final msg) => _ErrorView(message: msg),
              NotificationsLoaded() || NotificationsLoadingMore() => _NotificationList(
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

    final preferences = context.watch<NotificationPreferencesBloc>().state.preferences;
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
        itemCount: filteredNotifications.length + (state is NotificationsLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == filteredNotifications.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator(color: SoundCloudColors.orange)),
            );
          }

          final notification = filteredNotifications[index];
          return NotificationCard(
            notification: notification,
            onTap: () async {
              context.read<NotificationsBloc>().add(MarkNotificationRead(notification.id));
              await _navigateToContent(context, notification);
            },
            onDelete: () {
              context.read<NotificationsBloc>().add(DeleteNotification(notification.id));
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
      NotificationType.unknown => true,
    };
  }

  Future<void> _navigateToContent(
    BuildContext context,
    NotificationEntity notification,
  ) async {
    switch (notification.type) {
      case NotificationType.like:
      case NotificationType.follow:
      case NotificationType.repost:
        await _openActorProfile(context, notification);
        return;
      case NotificationType.comment:
        await _playTrackAndGoToOwnProfile(context, notification);
        return;
      case NotificationType.unknown:
        break;
    }

    final entityId = notification.entityId;

    if (entityId.isEmpty) return;

    switch (notification.entityType.toLowerCase()) {
      case 'track' || 'comment':
        await _playTrackAndGoToOwnProfile(context, notification);
      case 'user':
        final resolvedHandle = _sanitizeHandle(entityId);
        if (resolvedHandle.isEmpty) return;
        ProfileRoutes.goToProfile(context, resolvedHandle);
      default:
        break;
    }
  }

  Future<void> _openActorProfile(
    BuildContext context,
    NotificationEntity notification,
  ) async {
    final candidates = _buildFollowerHandleCandidates(notification);
    final resolvedHandle = await _resolveFirstReachableHandle(candidates);
    if (!context.mounted) return;

    if (resolvedHandle.isNotEmpty) {
      ProfileRoutes.goToProfile(context, resolvedHandle);
      return;
    }

    final fromSocialGraph = await _resolveHandleFromSocialGraph(
      context,
      <String>{notification.actorId.trim(), notification.entityId.trim()},
    );
    if (!context.mounted) return;

    if (fromSocialGraph.isNotEmpty) {
      ProfileRoutes.goToProfile(context, fromSocialGraph);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to open user profile right now')),
    );
  }

  List<String> _buildFollowerHandleCandidates(NotificationEntity notification) {
    final candidates = <String>[];

    final fromMessage = _extractHandleFromMessage(notification.message);
    if (_isLikelyHandle(fromMessage)) {
      candidates.add(fromMessage);
    }

    final fromEntity = _sanitizeHandle(notification.entityId);
    if (_isLikelyHandle(fromEntity)) {
      candidates.add(fromEntity);
    }

    final fromActor = _sanitizeHandle(notification.actorId);
    if (_isLikelyHandle(fromActor)) {
      candidates.add(fromActor);
    }

    final unique = <String>[];
    final seen = <String>{};
    for (final candidate in candidates) {
      if (candidate.isEmpty || seen.contains(candidate)) continue;
      seen.add(candidate);
      unique.add(candidate);
    }

    return unique;
  }

  Future<String> _resolveHandleFromSocialGraph(
    BuildContext context,
    Set<String> rawIdentifiers,
  ) async {
    if (!context.mounted) return '';

    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return '';
    if (!getIt.isRegistered<SocialRepo>()) return '';

    final normalizedIdentifiers = rawIdentifiers
        .map((raw) => raw.startsWith('@') ? raw.substring(1) : raw)
        .map((raw) => raw.trim())
        .where((raw) => raw.isNotEmpty)
        .toSet();

    if (normalizedIdentifiers.isEmpty) return '';

    final repo = getIt<SocialRepo>();

    String matchUsers(List<dynamic> users) {
      for (final user in users) {
        final userId = user.id.toString().trim();
        final handle = _sanitizeHandle(user.username.toString());
        for (final identifier in normalizedIdentifiers) {
          if (identifier == userId || _sanitizeHandle(identifier) == handle) {
            if (handle.isNotEmpty) return handle;
          }
        }
      }
      return '';
    }

    const limit = 100;

    try {
      for (var page = 1; page <= 5; page++) {
        final following = await repo.getFollowing(
          authState.user.id,
          page,
          limit: limit,
        );
        final found = matchUsers(following);
        if (found.isNotEmpty) return found;
        if (following.length < limit) break;
      }
    } catch (_) {}

    try {
      for (var page = 1; page <= 5; page++) {
        final followers = await repo.getFollowers(
          authState.user.id,
          page,
          limit: limit,
        );
        final found = matchUsers(followers);
        if (found.isNotEmpty) return found;
        if (followers.length < limit) break;
      }
    } catch (_) {}

    try {
      final suggested = await repo.getSuggestedUsers(page: 1, limit: limit);
      final found = matchUsers(suggested);
      if (found.isNotEmpty) return found;
    } catch (_) {}

    return '';
  }

  Future<String> _resolveFirstReachableHandle(List<String> candidates) async {
    if (candidates.isEmpty) return '';
    if (!getIt.isRegistered<GetProfileUseCase>()) return candidates.first;

    final getProfile = getIt<GetProfileUseCase>();
    for (final candidate in candidates) {
      try {
        final profile = await getProfile(candidate).timeout(
          const Duration(seconds: 4),
        );

        final resolved = _sanitizeHandle(profile.handle);
        if (resolved.isNotEmpty) return resolved;
        return candidate;
      } catch (_) {
        continue;
      }
    }

    return '';
  }

  void _goToOwnProfile(BuildContext context) {
    if (!context.mounted) return;

    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;

    final ownHandle = _sanitizeHandle(authState.user.handle);
    if (ownHandle.isEmpty) return;

    ProfileRoutes.goToProfile(context, ownHandle);
  }

  String _extractHandleFromMessage(String message) {
    final match = RegExp(r'@([A-Za-z0-9._-]+)').firstMatch(message);
    if (match == null) return '';
    return _sanitizeHandle(match.group(1) ?? '');
  }

  String _sanitizeHandle(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';

    var candidate = trimmed;
    if (candidate.startsWith('@')) {
      candidate = candidate.substring(1);
    }

    final valid = RegExp(r'^[A-Za-z0-9._-]+').firstMatch(candidate);
    if (valid == null) return '';
    return valid.group(0) ?? '';
  }

  bool _isLikelyHandle(String value) {
    final candidate = value.trim();
    if (candidate.isEmpty) return false;
    if (_isLikelyUuid(candidate)) return false;
    if (candidate.length < 2 || candidate.length > 40) return false;
    if (!RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(candidate)) return false;
    if (!RegExp(r'[A-Za-z]').hasMatch(candidate)) return false;
    return true;
  }

  bool _isLikelyUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }

  Future<void> _playTrackAndGoToOwnProfile(
    BuildContext context,
    NotificationEntity notification,
  ) async {
    final trackId = _resolveTrackId(notification);
    if (trackId.isEmpty) {
      _goToOwnProfile(context);
      return;
    }

    if (!getIt.isRegistered<GetTrackDetailUseCase>()) {
      _goToOwnProfile(context);
      return;
    }

    try {
      final result = await getIt<GetTrackDetailUseCase>()(trackId);
      final detail = result.detail;
      if (result.failure == null && detail != null && context.mounted) {
        await context.read<PlayerCubit>().playFromContext(
              tracks: [detail.toPlaybackTrack()],
              startIndex: 0,
              source: 'notifications',
            );
      }
    } catch (_) {
      // Keep navigation resilient even if playback setup fails.
    }

    _goToOwnProfile(context);
  }

  String _resolveTrackId(NotificationEntity notification) {
    final entityId = notification.entityId.trim();
    if (entityId.isEmpty) return '';

    final entityType = notification.entityType.trim().toLowerCase();
    if (entityType == 'track') return entityId;
    if (notification.type == NotificationType.like ||
        notification.type == NotificationType.repost) {
      return entityId;
    }

    return '';
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
            const Icon(Icons.error_outline, size: 60, color: SoundCloudColors.orange),
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
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                onPressed: () => context.read<NotificationsBloc>().add(const LoadNotifications()),
                child: const Text('RETRY'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}