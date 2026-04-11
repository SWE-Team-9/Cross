// app/router.dart
// Dart SDK
// Flutter
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// Third-party
// (go_router, flutter_bloc imported above)

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
import '../features/playback/presentation/pages/track_deep_link_bridge_page.dart';

// Project — recently played
import 'package:soundcloud_clone/features/recently_played/presentation/bloc/recently_played_cubit.dart';

// Project — library
import '../features/library/presentation/pages/library_page.dart';

// Project — home
import '../features/home/presentation/pages/mock_home_page.dart';

// ── Route name constants ──────────────────────────────────────────────────────
class AppRoutes {
  // Existing routes
  static const String home = '/home';
  static const String feed = '/feed';
  static const String search = '/search';
  static const String library = '/library';
  static const String upgrade = '/upgrade';
  static const String uploadPicker = '/upload-picker';
  static const String editProfile = '/profile/edit';
  static const String profile = '/profile/:handle';
  static const String followers = '/followers/:handle';
  static const String following = '/following/:handle';
  static const String trackManagementDemo = '/track-management-demo';

  // Deep link destinations — Sprint 4 T4.1
  static const String trackDetail = '/track/:trackId';
  static const String secretTrack = '/track/secret/:token';
  static const String playlist = '/playlist/:playlistId';
  // search already handles ?q= param — no new constant needed
}

// ── Path builders — used by deep link listener ────────────────────────────────
String _trackPath(String trackId) => '/track/$trackId';
String _secretPath(String token) => '/track/secret/$token';
String _profilePath(String handle) => '/profile/$handle';
String _playlistPath(String id) => '/playlist/$id';
String _searchPath(String query) => '/search?q=$query';

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

// ── Router factory ────────────────────────────────────────────────────────────
GoRouter _createRouter() {
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AuthRoutes.splash,
    routes: [
      // ── Auth (Sprint 1) ─────────────────────────────────────────────────
      ...AuthRoutes.routes,

      // ── Home ────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: MockHomePage(),
        ),
      ),

      // ── Feed ────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.feed,
        name: 'feed',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: _PlaceholderPage(title: 'Feed'),
        ),
      ),

      // ── Search (supports ?q= param from deep links) ──────────────────────
      GoRoute(
        path: AppRoutes.search,
        name: 'search',
        pageBuilder: (context, state) {
          final String? query = state.uri.queryParameters['q'];
          return NoTransitionPage(
            child: _PlaceholderPage(
              title: query != null ? 'Search: $query' : 'Search',
            ),
          );
        },
      ),

      // ── Upgrade ─────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.upgrade,
        name: 'upgrade',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: _PlaceholderPage(title: 'Upgrade'),
        ),
      ),

      // ── Library ─────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.library,
        name: 'library',
        pageBuilder: (context, state) => NoTransitionPage(
          child: BlocProvider(
            create: (_) => RecentlyPlayedCubit(),
            child: const LibraryPage(),
          ),
        ),
      ),

      // ── Upload picker (Sprint 1) ─────────────────────────────────────────
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

      // ── Edit profile (Sprint 2) ──────────────────────────────────────────
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

      // ── Profile (Sprint 2) ───────────────────────────────────────────────
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

      // ── Followers (Sprint 2) ─────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.followers,
        name: 'followers',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final handle = state.pathParameters['handle'] ?? '';
          return MaterialPage(child: FollowersPage(handle: handle));
        },
      ),

      // ── Following (Sprint 2) ─────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.following,
        name: 'following',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final handle = state.pathParameters['handle'] ?? '';
          return MaterialPage(child: FollowingPage(handle: handle));
        },
      ),

      // ── Track management demo (Sprint 2) ─────────────────────────────────
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

      // ── Track detail — public deep link (Sprint 4 T4.1) ─────────────────
      GoRoute(
        path: AppRoutes.trackDetail,
        name: 'track-detail',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final trackId = state.pathParameters['trackId'] ?? '';
          return MaterialPage(
            child: MultiBlocProvider(
              providers: [
                // PlayerCubit is a lazySingleton — reuse the existing instance
                BlocProvider.value(value: getIt<PlayerCubit>()),
                // TrackLoaderCubit is @injectable — fresh instance per page
                BlocProvider(create: (_) => getIt<TrackLoaderCubit>()),
              ],
              child: TrackDeepLinkBridgePage(trackId: trackId),
            ),
          );
        },
      ),

      // ── Secret track — private deep link (Sprint 4 T4.1) ────────────────
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

      // ── Playlist — stub until Module 7 (Sprint 4 T4.1) ──────────────────
      GoRoute(
        path: AppRoutes.playlist,
        name: 'playlist',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final playlistId = state.pathParameters['playlistId'] ?? '';
          return MaterialPage(
            child: _PlaceholderPage(title: 'Playlist $playlistId'),
          );
        },
      ),
    ],

    // ── 404 fallback ─────────────────────────────────────────────────────────
    errorBuilder: (context, state) => Scaffold(
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
    ),
  );

  // ── Deep link listener ────────────────────────────────────────────────────
  // Bridges DeepLinkService stream → go_router navigation.
  // Lives for the app lifetime — no need to cancel.
  getIt<DeepLinkService>().stream.listen((DeepLinkDestination destination) {
    switch (destination) {
      case TrackDeepLink(:final trackId):
        router.go(_trackPath(trackId));

      case SecretTrackDeepLink(:final secretToken):
        router.go(_secretPath(secretToken));

      case ProfileDeepLink(:final handle):
        router.go(_profilePath(handle));

      case PlaylistDeepLink(:final playlistId):
        router.go(_playlistPath(playlistId));

      case SearchDeepLink(:final query):
        router.go(_searchPath(query));

      case InvalidDeepLink(:final reason):
        debugPrint('[DeepLink] Invalid link ignored: $reason');
    }
  });

  return router;
}

// ── Router instances ──────────────────────────────────────────────────────────
final router = _createRouter();
GoRouter createRouter() => _createRouter();

// ── Placeholder page ──────────────────────────────────────────────────────────
class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction_outlined,
                  size: 56, color: Colors.white54),
              const SizedBox(height: 16),
              Text(
                '$title page is not implemented yet.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                'Temporary placeholder to keep navigation working on dev.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 20),
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
      ),
    );
  }
}
