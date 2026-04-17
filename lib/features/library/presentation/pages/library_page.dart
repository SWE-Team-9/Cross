import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:soundcloud_clone/core/widgets/bottom_nav_bar.dart';
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
        // ── Shared Bottom Nav (index 3 = Library) ──────────────────────────
        bottomNavigationBar: const BottomNavBar(selected: 3),
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
