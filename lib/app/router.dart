// coverage:ignore-file
// Flutter
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// Project — core
import '../core/deep_links/deep_link_destination.dart';
import '../core/deep_links/deep_link_service.dart';
import '../core/di/injector.dart';

// Project — auth
import '../features/auth/presentation/routes/auth_routes.dart';

// Project — profile
import '../features/profile/presentation/bloc/profile_cubit.dart';
import '../features/profile/presentation/pages/edit_profile_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';

// Project — social
import '../features/social/presentation/pages/followers_page.dart';
import '../features/social/presentation/pages/following_page.dart';
import '../features/social/presentation/pages/suggested_users_page.dart';

// Project — upload
import '../features/upload/domain/entities/managed_track.dart';
import '../features/upload/domain/entities/track_management_visibility.dart';
import '../features/upload/presentation/bloc/track_management_cubit.dart';
import '../features/upload/presentation/bloc/upload_picker_cubit.dart';
import '../features/upload/presentation/pages/track_management_page.dart';
import '../features/upload/presentation/pages/upload_picker_page.dart';

// Project — playback
import '../features/playback/presentation/bloc/player_cubit.dart';
import '../features/playback/presentation/bloc/track_loader_cubit.dart';
import '../features/playback/presentation/pages/full_player_page.dart';
import '../features/playback/presentation/pages/track_deep_link_bridge_page.dart';
import 'package:soundcloud_clone/features/interactions/presentation/bloc/track_interaction_cubit.dart';

// Project — library
import '../features/library/presentation/pages/downloaded_items_page.dart';
import '../features/library/presentation/pages/library_page.dart';

// Project — playlists
import '../features/playlists/domain/entities/playlist_entity.dart';
import '../features/playlists/presentation/bloc/playlists_cubit.dart';
import '../features/playlists/presentation/pages/playlist_detail_page.dart';
import '../features/playlists/presentation/pages/playlists_page.dart';
import '../core/widgets/bottom_nav_bar.dart';

// Project — notifications
import '../features/notifications/presentation/pages/notifications_page.dart';

// Project — home
import '../features/home/presentation/pages/home_page.dart';

// Project — feed
import '../features/feed/presentation/pages/feed_page.dart';

// Project — discovery
import '../features/discovery/presentation/page/discover_page.dart';
import '../features/discovery/domain/entities/resolved_resource.dart';
import '../features/discovery/domain/usecases/resolve_resource_usecase.dart';
// Project — search
import 'package:soundcloud_clone/features/search/presentation/bloc/search_cubit.dart';
import 'package:soundcloud_clone/features/search/presentation/pages/search_page.dart';
import 'package:soundcloud_clone/features/search/presentation/pages/genre_page.dart';
// Project — messaging
import '../features/messaging/domain/entities/conversation_entity.dart';
import '../features/messaging/presentation/pages/chat_thread_loader_page.dart';
import '../features/messaging/presentation/pages/chat_thread_page.dart';
import '../features/messaging/presentation/pages/inbox_page.dart';
import '../features/messaging/presentation/routes/messaging_routes.dart';

// Project — premium
import 'package:soundcloud_clone/features/premium/presentation/pages/billing_page.dart';
import 'package:soundcloud_clone/features/premium/presentation/pages/upgrade_page.dart';

class AppRoutes {
  static const String home = '/home';
  static const String feed = '/feed';
  static const String search = '/search';
  static const String discover = '/discover';
  static const String searchActive = '/search/active';
  static const String genre = '/genre/:genreSlug';

  static String genrePath(String genreSlug, {String? label}) {
    return Uri(
      path: '/genre/$genreSlug',
      queryParameters: {
        if (label != null && label.trim().isNotEmpty) 'label': label.trim(),
      },
    ).toString();
  }

  static const String library = '/library';
  static const String upgrade = '/upgrade';
  static const String billing = '/billing';
  static const String uploadPicker = '/upload-picker';
  static const String editProfile = '/profile/edit';
  static const String profile = '/profile/:handle';
  static const String followers = '/followers/:handle';
  static const String following = '/following/:handle';
  static const String suggestedUsers = '/suggested-users';
  static const String trackManagementDemo = '/track-management-demo';
  static const String player = '/player';
  static const String playlists = '/playlists';

  // ── Messaging ───────────────────────────────────────────────────────────
  static const String inbox = '/messages';
  static const String chatThread = '/messages/:conversationId';

  // ── Notifications ───────────────────────────────────────────────────────
  static const String notifications = '/notifications';

  // secretTrack MUST be before trackDetail — more specific path first
  static const String secretTrack = '/track/secret/:token';
  static const String trackDetail = '/track/:trackId';
  static const String secretPlaylist = '/playlist/secret/:token';
  static const String playlist = '/playlist/:playlistId';
}

// ── Path builders ─────────────────────────────────────────────────────────────

String _trackPath(String trackId) => '/track/$trackId';

String _secretPath(String token) => '/track/secret/$token';

String _profilePath(String handle) => '/profile/$handle';

String _playlistPath(String id) => '/playlist/$id';

String _secretPlaylistPath(String token) => '/playlist/secret/$token';

String _searchPath(String query) {
  return Uri(
    path: AppRoutes.search,
    queryParameters: {'q': query},
  ).toString();
}

Future<String?> _resolveResourcePath(String url) async {
  if (!getIt.isRegistered<ResolveResourceUseCase>()) return null;

  try {
    final resource = await getIt<ResolveResourceUseCase>()(url);

    if (!resource.matched || resource.resourceId.trim().isEmpty) {
      return null;
    }

    return switch (resource.type) {
      ResolvedResourceType.track => _trackPath(resource.resourceId),
      ResolvedResourceType.playlist => _playlistPath(resource.resourceId),
      ResolvedResourceType.artist =>
        resource.handle != null && resource.handle!.trim().isNotEmpty
            ? _profilePath(resource.handle!.trim())
            : null,
      ResolvedResourceType.unknown => null,
    };
  } catch (_) {
    return null;
  }
}

String _billingReturnPath(BillingReturnDeepLink destination) {
  final queryParameters = <String, String>{
    if (destination.status != null && destination.status!.trim().isNotEmpty)
      'status': destination.status!.trim(),
    if (destination.planCode != null && destination.planCode!.trim().isNotEmpty)
      'plan': destination.planCode!.trim(),
    if (destination.sessionId != null &&
        destination.sessionId!.trim().isNotEmpty)
      'session_id': destination.sessionId!.trim(),
    if (destination.checkoutSessionId != null &&
        destination.checkoutSessionId!.trim().isNotEmpty)
      'checkout_session_id': destination.checkoutSessionId!.trim(),
    if (destination.subscriptionId != null &&
        destination.subscriptionId!.trim().isNotEmpty)
      'subscription_id': destination.subscriptionId!.trim(),
  };

  final uri = Uri(
    path: AppRoutes.billing,
    queryParameters: queryParameters.isEmpty ? null : queryParameters,
  );

  return uri.toString();
}

Future<void> _handleDeepLinkDestination(
  DeepLinkDestination destination,
  GoRouter router,
) async {
  String? path;

  switch (destination) {
    case TrackDeepLink(:final trackId):
      path = _trackPath(trackId);

    case SecretTrackDeepLink(:final secretToken):
      path = _secretPath(secretToken);

    case ProfileDeepLink(:final handle):
      path = _profilePath(handle);

    case PlaylistDeepLink(:final playlistId):
      path = _playlistPath(playlistId);

    case SecretPlaylistDeepLink(:final secretToken):
      path = _secretPlaylistPath(secretToken);

    case SearchDeepLink(:final query):
      path = _searchPath(query);

    case ResolvableResourceDeepLink(:final url):
      path = await _resolveResourcePath(url);

    case HandleSlugDeepLink(:final handle, :final slug):
      path = '/resolve/$handle/$slug';

    case BillingReturnDeepLink():
      path = _billingReturnPath(destination);

    case OAuthCallbackDeepLink():
      router.go(AuthRoutes.oauthDebug, extra: destination);
      return;

    case InvalidDeepLink():
      return;
  }

  if (path == null || path.trim().isEmpty) return;

  final currentLocation =
      router.routerDelegate.currentConfiguration.uri.toString();

  final isOnAuthScreen = currentLocation.contains('/auth') ||
      currentLocation.contains('splash') ||
      currentLocation == '/';

  if (isOnAuthScreen) {
    _pendingDeepLink = path;
  } else {
    router.go(path);
  }
}
// ── Pending deep link ─────────────────────────────────────────────────────────

String? _pendingDeepLink;

String? getPendingDeepLink() {
  final String? path = _pendingDeepLink;
  _pendingDeepLink = null;
  return path;
}

class _RoutePathObserver extends NavigatorObserver {
  _RoutePathObserver(this._currentPath);

  final String Function() _currentPath;

  void _syncRoutePath() {
    _routePathNotifier.value = _currentPath();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _syncRoutePath();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _syncRoutePath();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _syncRoutePath();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _syncRoutePath();
  }
}

// ── Fallback seed for track management demo ───────────────────────────────────

ManagedTrack _fallbackTrackManagementSeed() {
  return const ManagedTrack(
    id: 'demo-track-001',
    title: 'Midnight Echoes',
    description: 'Sprint 2 local demo track for edit/delete testing.',
    genreId: 1,
    genreName: 'Ambient',
    tags: <String>['demo', 'sprint2'],
    visibility: TrackManagementVisibility.publicTrack,
    durationInSeconds: 212,
  );
}

String _labelFromGenreSlug(String slug) {
  return slug
      .split(RegExp(r'[-_\\s]+'))
      .where((part) => part.trim().isNotEmpty)
      .map((part) {
    final lower = part.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }).join(' ');
}

class _MainTabsShell extends StatelessWidget {
  const _MainTabsShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: navigationShell,
      bottomNavigationBar: keyboardOpen
          ? null
          : BottomNavBar(
              selected: navigationShell.currentIndex,
              onTap: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
            ),
    );
  }
}

// ── Route path notifier for optimized UI rebuilds ────────────────────────────
// Tracks current route path without expensive synchronous reads
final ValueNotifier<String> _routePathNotifier = ValueNotifier<String>('');

ValueNotifier<String> get currentRoutePathNotifier => _routePathNotifier;

GoRouter _createRouter() {
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  late final GoRouter router;

  router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AuthRoutes.splash,
    observers: [
      _RoutePathObserver(
        () => router.routerDelegate.currentConfiguration.uri.path,
      ),
    ],

    redirect: (context, state) {
      final location = state.uri.toString();
      // Update the route path notifier whenever route changes
      _routePathNotifier.value = state.uri.path;
      if (state.uri.path == AppRoutes.discover) {
        return '/feed/discover';
      }
      if (location.startsWith('/track/')) {
        return null;
      }
      return null;
    },

    routes: [
      // ── Auth ────────────────────────────────────────────────────────────────
      ...AuthRoutes.routes,

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _MainTabsShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomePage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.feed,
                name: 'feed',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: FeedPage(),
                ),
                routes: [
                  GoRoute(
                    path: 'discover',
                    name: 'discover-shell',
                    pageBuilder: (context, state) => const NoTransitionPage(
                      child: DiscoverPage(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.search,
                name: 'search',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: SearchPage(),
                ),
                routes: [
                  GoRoute(
                    path: 'active',
                    name: 'search-active',
                    pageBuilder: (context, state) {
                      final initialQuery = state.extra is String
                          ? state.extra as String
                          : state.uri.queryParameters['q'];

                      return NoTransitionPage(
                        child: BlocProvider<SearchCubit>(
                          create: (_) => getIt<SearchCubit>(),
                          child: SearchActivePage(initialQuery: initialQuery),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.library,
                name: 'library',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: LibraryPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.upgrade,
                name: 'upgrade',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: UpgradePage(),
                ),
              ),
            ],
          ),
        ],
      ),

      // ── Library downloads ─────────────────────────────────────────────────
      GoRoute(
        path: '/library/downloads/tracks',
        name: 'downloaded-tracks',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: DownloadedTracksPage(),
        ),
      ),
      GoRoute(
        path: '/library/downloads/playlists',
        name: 'downloaded-playlists',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: DownloadedPlaylistsPage(),
        ),
      ),

      // ── Genre discovery ────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.genre,
        name: 'genre',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final genreSlug = state.pathParameters['genreSlug'] ?? '';
          final label = state.uri.queryParameters['label'] ??
              _labelFromGenreSlug(genreSlug);

          return MaterialPage(
            child: GenrePage(
              genreLabel: label,
              genreQuery: genreSlug,
              genreColor: const Color(0xFFFF5500),
            ),
          );
        },
      ),
      // ── Premium ─────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.billing,
        name: 'billing',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          child: BillingPage(),
        ),
      ),

      // ── Playlists list ─────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.playlists,
        name: 'playlists',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          return MaterialPage(
            child: BlocProvider<PlaylistsCubit>(
              create: (_) => getIt<PlaylistsCubit>(),
              child: const PlaylistsPage(),
            ),
          );
        },
      ),

      // ── Notifications ─────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            const MaterialPage(child: NotificationsPage()),
      ),

      // ── Upload picker ───────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.uploadPicker,
        name: 'upload-picker',
        pageBuilder: (context, state) => MaterialPage(
          child: BlocProvider<UploadPickerCubit>(
            create: (_) => getIt<UploadPickerCubit>(),
            child: const UploadPickerPage(),
          ),
        ),
      ),

      // ── Edit profile ────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.editProfile,
        name: 'edit-profile',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final cubit = state.extra as ProfileCubit;
          return MaterialPage(
            child: BlocProvider.value(
              value: cubit,
              child: const EditProfilePage(),
            ),
          );
        },
      ),

      // ── Profile ─────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final handle = state.pathParameters['handle'] ?? '';
          return MaterialPage(
            child: ProfilePage(handle: handle),
          );
        },
      ),

      // ── Followers ───────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.followers,
        name: 'followers',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final handle = state.pathParameters['handle'] ?? '';
          return MaterialPage(child: FollowersPage(handle: handle));
        },
      ),

      // ── Following ───────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.following,
        name: 'following',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final handle = state.pathParameters['handle'] ?? '';
          return MaterialPage(child: FollowingPage(handle: handle));
        },
      ),

      // ── Suggested users ─────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.suggestedUsers,
        name: 'suggested-users',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          return const MaterialPage(child: SuggestedUsersPage());
        },
      ),

      // ── Track management ────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.trackManagementDemo,
        name: 'track-management',
        pageBuilder: (context, state) {
          final ManagedTrack initialTrack = state.extra is ManagedTrack
              ? state.extra as ManagedTrack
              : _fallbackTrackManagementSeed();
          return MaterialPage(
            child: BlocProvider<TrackManagementCubit>(
              create: (_) => getIt<TrackManagementCubit>(),
              child: TrackManagementPage(initialTrack: initialTrack),
            ),
          );
        },
      ),

      // ── Full player ─────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.player,
        name: 'player',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          child: BlocProvider(
            create: (_) => getIt<TrackInteractionCubit>(),
            child: const FullPlayerPage(),
          ),
          transitionDuration: const Duration(milliseconds: 180),
          reverseTransitionDuration: const Duration(milliseconds: 140),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            );
          },
        ),
      ),

      // ── Secret track — MUST be before trackDetail ───────────────────────────
      GoRoute(
        path: AppRoutes.secretTrack,
        name: 'secret-track',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final token = state.pathParameters['token'] ?? '';
          return MaterialPage(
            child: MultiBlocProvider(
              providers: [
                BlocProvider.value(value: getIt<PlayerCubit>()),
                BlocProvider(create: (_) => getIt<TrackLoaderCubit>()),
              ],
              child: TrackDeepLinkBridgePage(secretToken: token),
            ),
          );
        },
      ),

      // ── Track detail ────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.trackDetail,
        name: 'track-detail',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final trackId = state.pathParameters['trackId'] ?? '';
          return MaterialPage(
            child: MultiBlocProvider(
              providers: [
                BlocProvider.value(value: getIt<PlayerCubit>()),
                BlocProvider(create: (_) => getIt<TrackLoaderCubit>()),
              ],
              child: TrackDeepLinkBridgePage(trackId: trackId),
            ),
          );
        },
      ),

      // ── Handle/Slug resolver ─────────────────────────────────────────────────────
      GoRoute(
        path: '/resolve/:handle/:slug',
        name: 'resolve-handle-slug',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final handle = state.pathParameters['handle'] ?? '';
          final slug = state.pathParameters['slug'] ?? '';
          return MaterialPage(
            child: MultiBlocProvider(
              providers: [
                BlocProvider.value(value: getIt<PlayerCubit>()),
                BlocProvider(create: (_) => getIt<TrackLoaderCubit>()),
              ],
              child: TrackDeepLinkBridgePage(
                handle: handle,
                slug: slug,
              ),
            ),
          );
        },
      ),

      // ── Messaging ───────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.inbox,
        name: 'messages-inbox',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          return MaterialPage(
            child: InboxPage(
              onOpenConversation: (conversation) async {
                await MessagingRoutes.goToConversation(context, conversation);
              },
            ),
          );
        },
      ),

      GoRoute(
        path: AppRoutes.chatThread,
        name: 'messages-thread',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final conversationId = state.pathParameters['conversationId'] ?? '';
          final extra = state.extra;

          if (extra is ConversationEntity) {
            return MaterialPage(
              child: ChatThreadPage(
                conversationId: extra.conversationId,
                receiverId: extra.participant.id,
                participantDisplayName: extra.participant.displayName,
                participantHandle: extra.participant.handle,
                participantAvatarUrl: extra.participant.avatarUrl,
                canMessage: extra.canMessage,
                blockReason: extra.blockReason,
              ),
            );
          }

          return MaterialPage(
            child: ChatThreadLoaderPage(
              conversationId: conversationId,
            ),
          );
        },
      ),

      // ── Secret playlist — MUST be before playlist ───────────────────────────
      GoRoute(
        path: AppRoutes.secretPlaylist,
        name: 'secret-playlist',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final token = state.pathParameters['token'] ?? '';
          return MaterialPage(
            child: BlocProvider<PlaylistsCubit>(
              create: (_) => getIt<PlaylistsCubit>(),
              child: PlaylistDetailPage(
                playlistId: '',
                secretToken: token,
              ),
            ),
          );
        },
      ),

      // ── Playlist ────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.playlist,
        name: 'playlist',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final playlistId = state.pathParameters['playlistId'] ?? '';
          final initialPlaylist = state.extra is PlaylistEntity
              ? state.extra as PlaylistEntity
              : null;
          return MaterialPage(
            child: BlocProvider<PlaylistsCubit>(
              create: (_) => getIt<PlaylistsCubit>(),
              child: PlaylistDetailPage(
                playlistId: playlistId,
                initialPlaylist: initialPlaylist,
              ),
            ),
          );
        },
      ),
    ],

    // ── 404 fallback ─────────────────────────────────────────────────────────
    errorBuilder: (context, state) {
      final uri = state.uri.toString();

      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.link_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Page not found',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                uri,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text(
                  'Go Home',
                  style: TextStyle(color: Color(0xFFFF5500)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  final DeepLinkService deepLinkService = getIt<DeepLinkService>();

  final DeepLinkDestination? pending = deepLinkService.consumeLastDestination();
  if (pending != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleDeepLinkDestination(pending, router);
    });
  }

  deepLinkService.stream.listen((DeepLinkDestination destination) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleDeepLinkDestination(destination, router);
    });
  });

  return router;
}

final router = _createRouter();

GoRouter createRouter() => _createRouter();
