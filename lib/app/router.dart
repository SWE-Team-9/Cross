import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/di/injector.dart';

// Upload (existing — Sprint 1)
import '../features/upload/presentation/bloc/uploadPickerCubit.dart';
import '../features/upload/presentation/pages/UploadPickerPage.dart';

// Auth (existing — Sprint 1)
import '../features/auth/presentation/routes/auth_routes.dart';

// Profile image upload demo (Sprint 2 — T2.7 temporary demo/testing page)
import '../features/profile/presentation/pages/ProfileImageUploadDemoPage.dart';

// Profile (Sprint 2 — T2.1)
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/profile/presentation/pages/edit_profile_page.dart';
import '../features/social/presentation/pages/followers_page.dart';
import '../features/social/presentation/pages/following_page.dart';

// Recently Played
import 'package:soundcloud_clone/features/recently_played/presentation/bloc/recently_played_cubit.dart';

// Library
import '../features/library/presentation/pages/library_page.dart';

// Mock home page (temporary — replace with real home page in Sprint 4)
import '../features/home/presentation/pages/mock_home_page.dart';
import '../features/upload/presentation/bloc/trackManagementCubit.dart';
import '../features/upload/presentation/pages/TrackManagementPage.dart';
import '../features/upload/domain/entities/ManagedTrack.dart';
import '../features/upload/domain/entities/TrackManagementVisibility.dart';

// ── Navigator Keys ───────────────────────────────────────────────────────────
final _rootNavigatorKey = GlobalKey<NavigatorState>();

// ── Route name constants ─────────────────────────────────────────────────────
class AppRoutes {
  static const String home = '/home';
  static const String library = '/library';
  static const String uploadPicker = '/upload-picker';
  static const String profileImageUploadDemo = '/profile-image-upload-demo';
  static const String profile = '/profile/:userId';
  static const String editProfile = '/profile/edit';
  static const String followers = '/followers/:userId';
  static const String following = '/following/:userId';
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

// ── Router ───────────────────────────────────────────────────────────────────
final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.home,
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

    // ── Profile image upload demo (Sprint 2 — T2.7) ──────────────
    GoRoute(
      path: AppRoutes.profileImageUploadDemo,
      name: 'profile-image-upload-demo',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => const MaterialPage(
        child: ProfileImageUploadDemoPage(),
      ),
    ),

    // ── Profile (Sprint 2 — T2.1) ────────────────────────────────
    GoRoute(
      path: AppRoutes.profile,
      name: 'profile',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return MaterialPage(
          child: ProfilePage(userId: userId),
        );
      },
    ),

    GoRoute(
      path: AppRoutes.editProfile,
      name: 'edit-profile',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => const MaterialPage(
        child: EditProfilePage(),
      ),
    ),

    GoRoute(
      path: AppRoutes.followers,
      name: 'followers',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return MaterialPage(
          child: FollowersPage(userId: userId),
        );
      },
    ),

    GoRoute(
      path: AppRoutes.following,
      name: 'following',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return MaterialPage(
          child: FollowingPage(userId: userId),
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
