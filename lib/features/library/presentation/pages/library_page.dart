import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:soundcloud_clone/features/recently_played/presentation/bloc/recently_played_cubit.dart';
import 'package:soundcloud_clone/features/recently_played/presentation/widgets/recently_played_row.dart';
import 'package:soundcloud_clone/core/models/track.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: GetIt.I<RecentlyPlayedCubit>(), // ✅ SAME INSTANCE
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
          actions: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.cast, color: Colors.white70),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.settings, color: Colors.white70),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xFFFF5500),
                child: Text(
                  'EY',
                  style: TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
            ),
            SizedBox(width: 8),
          ],
        ),

        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _LibraryItem(title: 'Your likes'),
              _LibraryItem(title: 'Playlists'),
              _LibraryItem(title: 'Albums'),
              _LibraryItem(title: 'Following'),
              _LibraryItem(title: 'Stations'),
              _LibraryItem(title: 'Your insights'),
              _LibraryItem(title: 'Your uploads'),
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

        // ✅ BOTTOM NAV ADDED
        bottomNavigationBar: _BottomNav(selected: 3),
      ),
    );
  }
}

class _LibraryItem extends StatelessWidget {
  final String title;

  const _LibraryItem({required this.title});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.white54,
      ),
      onTap: () {},
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
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final int index, selected;
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
