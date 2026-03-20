import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/di/injector.dart';

// Upload (existing — Sprint 1)
import '../features/upload/presentation/bloc/uploadPickerCubit.dart';
import '../features/upload/presentation/pages/UploadPickerPage.dart';

// Auth (existing — Sprint 1)
import '../features/auth/presentation/routes/auth_routes.dart';

// Profile (Sprint 2 — T2.1)
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/profile/presentation/pages/edit_profile_page.dart';
import '../features/social/presentation/pages/followers_page.dart';
import '../features/social/presentation/pages/following_page.dart';

// Library
import '../features/library/presentation/pages/library_page.dart';

// Mock home page (temporary — replace with real home page in Sprint 4)
import '../features/home/presentation/pages/mock_home_page.dart';

// ── Navigator Keys ───────────────────────────────────────────────────────────
final _rootNavigatorKey = GlobalKey<NavigatorState>();

// ── Route name constants ──────────────────────────────────────────────────────
class AppRoutes {
  static const String home = '/home';
  static const String library = '/library';
  static const String uploadPicker = '/upload-picker';
  static const String profile = '/profile/:userId';
  static const String editProfile = '/profile/edit';
  static const String followers = '/followers/:userId';
  static const String following = '/following/:userId';
}

// ── Router ────────────────────────────────────────────────────────────────────
final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.home,

  routes: [
    // ── Auth (Sprint 1) ───────────────────────────────────────────
    ...AuthRoutes.routes,

    // ── Home ───────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: MockHomePage(),
      ),
    ),

    GoRoute(
      path: AppRoutes.library,
      name: 'library',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: LibraryPage(),
      ),
    ),

    // ── Upload picker ──────────────────────────────────────────────
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

    // ── Profile (Sprint 2 — T2.1) ─────────────────────────────────
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
  ],

  // ── 404 fallback ─────────────────────────────────────────────────
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
