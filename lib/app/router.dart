import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/di/injector.dart';

// Profile
import '../features/profile/presentation/bloc/profile_cubit.dart';

// Upload (existing — Sprint 1)
import '../features/upload/domain/entities/managed_track.dart';
import '../features/upload/domain/entities/track_management_visibility.dart';
import '../features/upload/presentation/bloc/track_management_cubit.dart';
import '../features/upload/presentation/bloc/upload_picker_cubit.dart';
import '../features/upload/presentation/pages/track_management_page.dart';
import '../features/upload/presentation/pages/upload_picker_page.dart';

// Auth (existing — Sprint 1)
import '../features/auth/presentation/routes/auth_routes.dart';

// Profile (Sprint 2 — T2.1)
import '../features/profile/presentation/pages/edit_profile_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/social/presentation/pages/followers_page.dart';
import '../features/social/presentation/pages/following_page.dart';

// Recently Played
import 'package:soundcloud_clone/features/recently_played/presentation/bloc/recently_played_cubit.dart';

// Library
import '../features/library/presentation/pages/library_page.dart';

// Mock home page (temporary — replace with real home page in Sprint 4)
import '../features/home/presentation/pages/mock_home_page.dart';
import '../features/playback/presentation/pages/full_player_page.dart';

// ── Route name constants ─────────────────────────────────────────────────────
class AppRoutes {
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
}

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

// ── Router Configuration ─────────────────────────────────────────────────────
GoRouter _createRouter() {
  // ✅ FIX: Create a unique Navigator key for every router instance.
  // This prevents "Duplicate GlobalKey" errors during widget testing.
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AuthRoutes.splash,
    routes: [
      // ── Auth (Sprint 1) ───────────────────────────────────────────
      ...AuthRoutes.routes,

      // ── Home ──────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: MockHomePage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.feed,
        name: 'feed',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: _PlaceholderPage(title: 'Feed'),
        ),
      ),

      GoRoute(
        path: AppRoutes.search,
        name: 'search',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: _PlaceholderPage(title: 'Search'),
        ),
      ),

      GoRoute(
        path: AppRoutes.upgrade,
        name: 'upgrade',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: _PlaceholderPage(title: 'Upgrade'),
        ),
      ),

      // ── Library ───────────────────────────────────────────────────
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

      // ── Upload picker (Sprint 1) ──────────────────────────────────
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

      // ── Profile (Sprint 2 — T2.1) ────────────────────────────────
      GoRoute(
        path: AppRoutes.editProfile,
        name: 'edit-profile',
        parentNavigatorKey: rootNavigatorKey, // ✅ Uses the local key
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

      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        parentNavigatorKey: rootNavigatorKey, // ✅ Uses the local key
        pageBuilder: (context, state) {
          final handle = state.pathParameters['handle'] ?? '';
          return MaterialPage(
            child: ProfilePage(handle: handle),
          );
        },
      ),

      // ── Social (Followers/Following) ──────────────────────────────
      GoRoute(
        path: AppRoutes.followers,
        name: 'followers',
        parentNavigatorKey: rootNavigatorKey, // ✅ Uses the local key
        pageBuilder: (context, state) {
          final handle = state.pathParameters['handle'] ?? '';
          return MaterialPage(
            child: FollowersPage(handle: handle),
          );
        },
      ),

      GoRoute(
        path: AppRoutes.following,
        name: 'following',
        parentNavigatorKey: rootNavigatorKey, // ✅ Uses the local key
        pageBuilder: (context, state) {
          final handle = state.pathParameters['handle'] ?? '';
          return MaterialPage(
            child: FollowingPage(handle: handle),
          );
        },
      ),

      // ── Track management demo (Sprint 2) ─────────────────────────
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
              child: TrackManagementPage(
                initialTrack: initialTrack,
              ),
            ),
          );
        },
      ),

      GoRoute(
        path: '/player',
        name: 'player',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          child: FullPlayerPage(),
        ),
      ),
    ],

    // ── 404 fallback ───────────────────────────────────────────────
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
}

// ── Router instance (for app use) ──────────────────────────────────────────
// This is used by the main application entry point.
final router = _createRouter();

// ── Factory method for testing (creates fresh router instance) ─────────────
// This is used by your router_test.dart to get an isolated router.
GoRouter createRouter() {
  return _createRouter();
}

// ── Placeholder Page ───────────────────────────────────────────────────────
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
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
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
