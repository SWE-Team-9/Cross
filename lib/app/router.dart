import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/di/injector.dart';

import '../features/profile/presentation/bloc/profile_cubit.dart';

import '../features/upload/domain/entities/managed_track.dart';
import '../features/upload/domain/entities/track_management_visibility.dart';
import '../features/upload/presentation/bloc/track_management_cubit.dart';
import '../features/upload/presentation/bloc/upload_picker_cubit.dart';
import '../features/upload/presentation/pages/track_management_page.dart';
import '../features/upload/presentation/pages/upload_picker_page.dart';

import '../features/auth/presentation/routes/auth_routes.dart';

import '../features/profile/presentation/pages/edit_profile_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/social/presentation/pages/followers_page.dart';
import '../features/social/presentation/pages/following_page.dart';

import 'package:soundcloud_clone/features/recently_played/presentation/bloc/recently_played_cubit.dart';

import '../features/library/presentation/pages/library_page.dart';

import '../features/home/presentation/pages/mock_home_page.dart';
import '../features/playback/presentation/pages/full_player_page.dart';

import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/playback_cubit.dart';

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

GoRouter _createRouter() {
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AuthRoutes.splash,
    routes: [
      ...AuthRoutes.routes,

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

      GoRoute(
        path: AppRoutes.followers,
        name: 'followers',
        parentNavigatorKey: rootNavigatorKey,
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
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final handle = state.pathParameters['handle'] ?? '';
          return MaterialPage(
            child: FollowingPage(handle: handle),
          );
        },
      ),

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

      // ✅ الـ player بيجيب الـ cubits من الـ context مش من getIt
      GoRoute(
        path: '/player',
        name: 'player',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => MaterialPage(
          child: MultiBlocProvider(
            providers: [
              BlocProvider.value(
                value: context.read<PlaybackCubit>(),
              ),
              BlocProvider.value(
                value: context.read<PlayerCubit>(),
              ),
            ],
            child: const FullPlayerPage(),
          ),
        ),
      ),
    ],
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

final router = _createRouter();

GoRouter createRouter() {
  return _createRouter();
}

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
