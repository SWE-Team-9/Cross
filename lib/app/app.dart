import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/deep_links/deep_link_destination.dart';
import '../core/deep_links/deep_link_service.dart';
import '../core/di/injector.dart';
import '../core/notifiers/overlay_notifiers.dart';
import '../core/widgets/bottom_nav_bar.dart';
import '../features/auth/presentation/bloc/auth_cubit.dart';
import '../features/auth/presentation/routes/auth_routes.dart';
import '../features/comments/presentation/bloc/comments_cubit.dart';
import '../features/comments/presentation/pages/track_comments_page.dart';
import '../features/messaging/presentation/routes/messaging_routes.dart';
import '../features/notifications/data/services/fcm_registration_service.dart';
import '../features/notifications/data/services/notifications_realtime_refresh_service.dart';
import '../features/notifications/domain/entities/notification_entity.dart';
import '../features/notifications/domain/entities/notification_tap_target.dart';
import '../features/notifications/domain/usecases/resolve_notification_tap_target_use_case.dart';
import '../features/notifications/presentation/bloc/notification_preferences_bloc.dart';
import '../features/notifications/presentation/bloc/notifications_bloc.dart';
import '../features/playback/presentation/bloc/playback_cubit.dart';
import '../features/playback/presentation/bloc/player_cubit.dart';
import '../features/playback/presentation/bloc/player_ui_state.dart';
import '../features/playback/presentation/widgets/mini_player.dart';
import '../features/profile/presentation/routes/profile_routes.dart';
import '../features/social/data/repositories/social_repo.dart';
import 'router.dart';

const Set<String> _miniPlayerHiddenRoutes = <String>{
  AuthRoutes.splash,
  AuthRoutes.welcome,
  AuthRoutes.login,
  AuthRoutes.register,
  AuthRoutes.completeProfile,
  AuthRoutes.forgotPassword,
  AuthRoutes.resetPassword,
  AuthRoutes.verifyEmail,
  AuthRoutes.oauthDebug,
  AppRoutes.player,
  AppRoutes.trackManagementDemo,
  AppRoutes.uploadPicker,
  AppRoutes.discover,
};

bool _shouldHideMiniPlayerForPath(String path) {
  if (_miniPlayerHiddenRoutes.contains(path)) return true;

  return path.startsWith('/track-management') ||
      path.startsWith('/followers/') ||
      path.startsWith('/following/');
}

class App extends StatelessWidget {
  App({super.key, GoRouter? routerConfig})
      : routerConfig = routerConfig ?? router;

  final GoRouter routerConfig;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SocialRepo>.value(
          value: getIt<SocialRepo>(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => getIt<AuthCubit>(),
          ),
          BlocProvider(
            create: (_) => getIt<PlayerCubit>(),
          ),
          BlocProvider(
            create: (_) => getIt<PlaybackCubit>(),
          ),
          BlocProvider(
            create: (_) =>
                getIt<NotificationsBloc>()..add(const LoadNotifications()),
          ),
          BlocProvider(
            create: (_) => getIt<NotificationPreferencesBloc>(),
          ),
        ],
        child: _NotificationRefreshBridge(
          child: MultiBlocListener(
            listeners: [
              BlocListener<AuthCubit, AuthState>(
                listenWhen: (previous, current) =>
                    current is AuthAuthenticated &&
                    previous is! AuthAuthenticated,
                listener: (context, state) {
                  getIt<NotificationsRealtimeRefreshService>().start();
                  context
                      .read<NotificationsBloc>()
                      .add(const LoadNotifications());
                },
              ),
              BlocListener<AuthCubit, AuthState>(
                listenWhen: (previous, current) =>
                    current is AuthUnauthenticated &&
                    previous is! AuthUnauthenticated,
                listener: (context, state) {
                  getIt<NotificationsRealtimeRefreshService>().stop();
                },
              ),
            ],
            child: MaterialApp.router(
              title: 'Iqa3',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                primarySwatch: Colors.orange,
                useMaterial3: true,
              ),
              routerConfig: routerConfig,
              builder: (context, child) {
                return BlocBuilder<PlayerCubit, PlayerUIState>(
                  builder: (context, playerState) {
                    final isPlayerOpen = playerState.isFullScreen;
                    final hasMiniPlayerTrack = playerState.currentTrack != null;

                    return _DeepLinkBridge(
                      child: Scaffold(
                        backgroundColor: Colors.black,
                        body: ValueListenableBuilder<bool>(
                          valueListenable: isTrackSheetOpen,
                          builder: (context, sheetOpen, _) {
                            final currentPath = router
                                .routerDelegate.currentConfiguration.uri.path;
                            final showMiniPlayerOnRoute =
                                !_shouldHideMiniPlayerForPath(currentPath);
                            final showMiniPlayer = hasMiniPlayerTrack &&
                                showMiniPlayerOnRoute &&
                                playerState.showMiniPlayer &&
                                !isPlayerOpen &&
                                !sheetOpen;
                            final safeAreaBottom =
                                MediaQuery.paddingOf(context).bottom;
                            final miniPlayerBottomOffset =
                                safeAreaBottom + BottomNavBar.minHeight + 8;

                            return Stack(
                              children: [
                                Positioned.fill(
                                  child: child ?? const SizedBox.shrink(),
                                ),
                                if (hasMiniPlayerTrack && showMiniPlayerOnRoute)
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: miniPlayerBottomOffset,
                                    child: IgnorePointer(
                                      ignoring: !showMiniPlayer,
                                      child: AnimatedSlide(
                                        duration:
                                            const Duration(milliseconds: 220),
                                        curve: Curves.easeOutCubic,
                                        offset: showMiniPlayer
                                            ? Offset.zero
                                            : const Offset(0, 1.2),
                                        child: AnimatedOpacity(
                                          duration: const Duration(
                                            milliseconds: 180,
                                          ),
                                          curve: Curves.easeOut,
                                          opacity: showMiniPlayer ? 1 : 0,
                                          child: const MiniPlayer(),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationRefreshBridge extends StatefulWidget {
  const _NotificationRefreshBridge({required this.child});

  final Widget child;

  @override
  State<_NotificationRefreshBridge> createState() =>
      _NotificationRefreshBridgeState();
}

class _NotificationRefreshBridgeState
    extends State<_NotificationRefreshBridge> {
  StreamSubscription<void>? _fcmSubscription;
  StreamSubscription<void>? _realtimeSubscription;
  StreamSubscription<NotificationEntity>? _notificationTapSubscription;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (!getIt.isRegistered<NotificationsRealtimeRefreshService>()) {
        return;
      }

      final realtimeService = getIt<NotificationsRealtimeRefreshService>();
      FcmRegistrationService? service;

      try {
        if (getIt.isRegistered<FcmRegistrationService>()) {
          service = getIt<FcmRegistrationService>();
        }
      } catch (_) {
        service = null;
      }

      if (service != null) {
        _fcmSubscription = service.notificationRefreshStream.listen((_) {
          _scheduleRefresh();
        });

        _notificationTapSubscription =
            service.notificationTapStream.listen(_handleNotificationTap);

        final pendingNotification = service.consumeLastOpenedNotification();
        if (pendingNotification != null) {
          _handleNotificationTap(pendingNotification);
        }
      }

      _realtimeSubscription = realtimeService.refreshStream.listen((_) {
        _scheduleRefresh();
      });
    });
  }

  Future<void> _handleNotificationTap(NotificationEntity notification) async {
    if (!mounted) return;

    final resolver = getIt<ResolveNotificationTapTargetUseCase>();
    final target = await resolver(notification);
    if (!mounted) return;

    switch (target) {
      case NotificationCommentsTapTarget(trackId: final trackId):
        await _openTrackComments(trackId);
        break;
      case NotificationConversationTapTarget(conversation: final conversation):
        await MessagingRoutes.goToConversation(context, conversation);
        break;
      case NotificationProfileTapTarget(handle: final handle):
        ProfileRoutes.goToProfile(context, handle);
        break;
      case null:
        return;
    }

    if (mounted && notification.id.isNotEmpty) {
      context
          .read<NotificationsBloc>()
          .add(MarkNotificationRead(notification.id));
    }
  }

  Future<void> _openTrackComments(String trackId) async {
    if (trackId.trim().isEmpty || !mounted) return;

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

  void _scheduleRefresh() {
    if (!mounted) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      context.read<NotificationsBloc>().add(const LoadNotifications());
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _fcmSubscription?.cancel();
    _realtimeSubscription?.cancel();
    _notificationTapSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _DeepLinkBridge extends StatefulWidget {
  const _DeepLinkBridge({required this.child});

  final Widget child;

  @override
  State<_DeepLinkBridge> createState() => _DeepLinkBridgeState();
}

class _DeepLinkBridgeState extends State<_DeepLinkBridge> {
  StreamSubscription<DeepLinkDestination>? _subscription;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final deepLinkService = getIt<DeepLinkService>();

      final pending = deepLinkService.peekLastDestination();
      if (pending is OAuthCallbackDeepLink) {
        deepLinkService.markLastDestinationConsumed();
        _handleDestination(pending);
      }

      _subscription = deepLinkService.stream.listen(_handleDestination);
    });
  }

  void _handleDestination(DeepLinkDestination destination) {
    if (!mounted) return;

    if (destination is OAuthCallbackDeepLink) {
      router.go(AuthRoutes.oauthDebug, extra: destination);
    } else if (destination is TrackDeepLink) {
      router.go('/track/${destination.trackId}');
    } else if (destination is PlaylistDeepLink) {
      router.go('/playlist/${destination.playlistId}');
    } else if (destination is ProfileDeepLink) {
      router.go('/profile/${destination.handle}');
    } else if (destination is SearchDeepLink) {
      router.go('/search?q=${destination.query}');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}