import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/recently_played/presentation/bloc/recently_played_cubit.dart';
import 'package:soundcloud_clone/features/recently_played/presentation/widgets/recently_played_row.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/utils/platform_url_utils.dart';
import 'package:soundcloud_clone/features/settings/presentation/page/settings_page.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: GetIt.I<RecentlyPlayedCubit>(),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          title: const Text(
            'Library',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.cast, color: Colors.white70),
            ),
            // ✅ زرار settings بيفتح الـ SettingsPage
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white70),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<AuthCubit>(),
                      child: const SettingsPage(),
                    ),
                  ),
                );
              },
            ),
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                String? avatarUrl;
                String fallbackText = '?';

                if (state is AuthAuthenticated) {
                  avatarUrl = state.user.avatarUrl;
                  fallbackText = state.user.handle.isNotEmpty
                      ? state.user.handle.substring(0, 1).toUpperCase()
                      : '?';
                }

                final normalizedAvatarUrl =
                    PlatformUrlUtils.normalizeBackendUrl(avatarUrl);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFFFF5500),
                    backgroundImage: normalizedAvatarUrl != null
                        ? NetworkImage(normalizedAvatarUrl)
                        : null,
                    child: normalizedAvatarUrl == null
                        ? Text(
                            fallbackText,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _LibraryItem(title: 'Your likes', onTap: () {}),
              _LibraryItem(title: 'Playlists', onTap: () {}),
              _LibraryItem(title: 'Albums', onTap: () {}),
              // ✅ Following بيفتح الـ FollowingPage بتاع اليوزر الحالي
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  return _LibraryItem(
                    title: 'Following',
                    onTap: () {
                      if (state is AuthAuthenticated) {
                        context.push('/following/${state.user.handle}');
                      }
                    },
                  );
                },
              ),
              _LibraryItem(title: 'Stations', onTap: () {}),
              _LibraryItem(title: 'Your insights', onTap: () {}),
              _LibraryItem(title: 'Your uploads', onTap: () {}),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recently played',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('See all'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              BlocBuilder<RecentlyPlayedCubit, List<Track>>(
                builder: (context, tracks) {
                  if (tracks.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'No recently played tracks yet',
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }
                  return RecentlyPlayedRow(tracks: tracks);
                },
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'Listening history',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
        bottomNavigationBar: const _BottomNav(selected: 3),
      ),
    );
  }
}

class _LibraryItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _LibraryItem({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: onTap,
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int selected;

  const _BottomNav({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Color(0xFF1F1F1F))),
      ),
      child: Row(
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
            index: 0,
            selected: selected,
            onTap: () => context.go('/home'),
          ),
          _NavItem(
            icon: Icons.grid_view_outlined,
            activeIcon: Icons.grid_view,
            label: 'Feed',
            index: 1,
            selected: selected,
            onTap: () => context.go('/feed'),
          ),
          _NavItem(
            icon: Icons.search,
            activeIcon: Icons.search,
            label: 'Search',
            index: 2,
            selected: selected,
            onTap: () => context.go('/search'),
          ),
          _NavItem(
            icon: Icons.library_music_outlined,
            activeIcon: Icons.library_music,
            label: 'Library',
            index: 3,
            selected: selected,
            onTap: () => context.go('/library'),
          ),
          _NavItem(
            icon: Icons.bar_chart_outlined,
            activeIcon: Icons.bar_chart,
            label: 'Upgrade',
            index: 4,
            selected: selected,
            onTap: () => context.go('/upgrade'),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = selected == index;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active ? activeIcon : icon,
                color: active ? Colors.white : const Color(0xFF555555),
                size: 22,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : const Color(0xFF555555),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
