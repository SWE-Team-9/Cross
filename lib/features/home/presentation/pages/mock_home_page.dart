import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '/features/profile/presentation/routes/profile_routes.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/widgets/track_row.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/managed_track.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_management_visibility.dart';
import 'package:soundcloud_clone/features/upload/presentation/models/apply_track_management_result.dart';
import 'package:soundcloud_clone/features/upload/presentation/models/track_management_result.dart';
import 'package:soundcloud_clone/core/utils/platform_url_utils.dart';

class MockHomePage extends StatefulWidget {
  const MockHomePage({super.key});

  @override
  State<MockHomePage> createState() => _MockHomePageState();
}

class _MockHomePageState extends State<MockHomePage> {
  int _selectedTab = 0;
  String _selectedGenre = 'ELECTRONIC';

  final _genres = const [
    'ELECTRONIC',
    'FOLK',
    'HOUSE',
    'TECHNO',
    'POP',
    'HIP-HOP',
  ];

  List<ManagedTrack> _managedTracks = const [
    ManagedTrack(
      id: 'managed-track-1',
      title: 'Midnight Echoes',
      description: 'A temporary owner track for Sprint 2 testing.',
      genreId: 1,
      genreName: 'Ambient',
      tags: <String>['owner', 'ambient'],
      visibility: TrackManagementVisibility.publicTrack,
      durationInSeconds: 212,
    ),
    ManagedTrack(
      id: 'managed-track-2',
      title: 'City Lights',
      description: 'Second temporary owner track for edit/delete testing.',
      genreId: 2,
      genreName: 'Electronic',
      tags: <String>['night', 'synth'],
      visibility: TrackManagementVisibility.privateTrack,
      durationInSeconds: 184,
    ),
  ];

  Future<void> _openTrackManagement(ManagedTrack track) async {
    final result = await context.pushNamed(
      'track-management',
      extra: track,
    );

    if (result is TrackManagementResult && mounted) {
      setState(() {
        _managedTracks = applyTrackManagementResult(
          tracks: _managedTracks,
          result: result,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go('/welcome');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        String currentHandle = '';
        if (state is AuthAuthenticated) {
          currentHandle = state.user.handle;
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Column(
              children: [
                _TopBar(
                  currentUserHandle: currentHandle,
                  authState: state,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionHeader(title: 'More of what you like'),
                        const _RelatedTracksRow(),
                        const _SectionHeader(title: 'Mixed for you'),
                        _MixesRow(userHandle: currentHandle),
                        const _SectionHeader(
                            title: 'Your Tracks (Sprint 2 Test)'),
                        _ManagedTracksSection(
                          tracks: _managedTracks,
                          onManageTap: _openTrackManagement,
                        ),
                        const _SectionHeader(title: 'Trending by genre'),
                        _GenreChips(
                          genres: _genres,
                          selected: _selectedGenre,
                          onSelect: (g) =>
                              setState(() => _selectedGenre = g),
                        ),
                        const _TrendingTracks(),
                        const SizedBox(height: 100), // ← مسافة للـ mini player
                      ],
                    ),
                  ),
                ),
                _BottomNav(
                  selected: _selectedTab,
                  onTap: (i) {
                    setState(() => _selectedTab = i);
                    switch (i) {
                      case 0:
                        break;
                      case 1:
                        context.go('/feed');
                        break;
                      case 2:
                        context.go('/search');
                        break;
                      case 3:
                        context.go('/library');
                        break;
                      case 4:
                        context.go('/upgrade');
                        break;
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String currentUserHandle;
  final AuthState authState;

  const _TopBar({
    required this.currentUserHandle,
    required this.authState,
  });

  void _showLogoutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Log out of Iqa3?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5500),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(bContext);
                    context.read<AuthCubit>().logout();
                  },
                  child: const Text(
                    'Log out',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(bContext),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToProfile(BuildContext context) {
    if (currentUserHandle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to view profile'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    ProfileRoutes.goToProfile(context, currentUserHandle);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 8),
      child: Row(
        children: [
          const Text(
            'Home',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'GET PRO',
            style: TextStyle(
              color: Color(0xFFFF5500),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (authState is AuthAuthenticated)
            _IconBtn(
              icon: Icons.logout_rounded,
              onTap: () => _showLogoutSheet(context),
            ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _navigateToProfile(context),
            child: Builder(
              builder: (_) {
                String? avatarUrl;
                String fallbackText = '?';

                if (authState is AuthAuthenticated) {
                  final user = (authState as AuthAuthenticated).user;
                  avatarUrl = user.avatarUrl;
                  fallbackText = user.handle.isNotEmpty
                      ? user.handle.substring(0, 1).toUpperCase()
                      : '?';
                } else if (currentUserHandle.isNotEmpty) {
                  fallbackText =
                      currentUserHandle.substring(0, 1).toUpperCase();
                }

                final normalizedAvatarUrl =
                    PlatformUrlUtils.normalizeBackendUrl(avatarUrl);

                return CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFFFF5500),
                  backgroundImage: normalizedAvatarUrl != null
                      ? NetworkImage(normalizedAvatarUrl)
                      : null,
                  child: normalizedAvatarUrl == null
                      ? Text(
                          fallbackText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                );
              },
            ),
          ),
          const SizedBox(width: 4),
          _IconBtn(icon: Icons.cast, onTap: () {}),
          _IconBtn(
            icon: Icons.upload_outlined,
            onTap: () => context.push('/upload-picker'),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: Colors.white70, size: 22),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RelatedTracksRow extends StatelessWidget {
  const _RelatedTracksRow();

  void _navigateToProfile(BuildContext context, String handle) {
    if (handle.isNotEmpty) {
      ProfileRoutes.goToProfile(context, handle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      const _AlbumData(
        label: 'Related tracks: L...',
        sub: 'SoundCloud',
        handle: 'sc1',
        topText: 'Cage\nThe\nElephant',
        color1: Color(0xFF1a1a2e),
        color2: Color(0xFF16213e),
      ),
      const _AlbumData(
        label: 'Related tracks: E...',
        sub: 'SoundCloud',
        handle: 'sc2',
        topText: 'THE\nStrokes',
        color1: Color(0xFF2d1b2e),
        color2: Color(0xFF8b1a1a),
      ),
      const _AlbumData(
        label: 'Related tracks: A...',
        sub: 'SoundCloud',
        handle: 'sc3',
        topText: 'ARABIC\nARTISTS',
        color1: Color(0xFF2a2a1a),
        color2: Color(0xFF1a2a1a),
      ),
    ];

    return SizedBox(
      height: 192,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final c = cards[i];
          return GestureDetector(
            onTap: () => _navigateToProfile(context, c.handle),
            child: SizedBox(
              width: 148,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 148,
                    height: 148,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient:
                          LinearGradient(colors: [c.color1, c.color2]),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      c.topText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c.label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    c.sub,
                    style: const TextStyle(
                      color: Color(0xFF999999),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MixesRow extends StatelessWidget {
  final String userHandle;

  const _MixesRow({required this.userHandle});

  void _navigateToProfile(BuildContext context) {
    if (userHandle.isNotEmpty) {
      ProfileRoutes.goToProfile(context, userHandle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mixes = [
      const _MixData(
        label: 'MIX 1',
        sub: 'Balthazar, Cage...',
        badgeColor: Color(0xFF8250C8),
        color1: Color(0xFF1a1a1a),
        color2: Color(0xFF2d1b2e),
      ),
      const _MixData(
        label: 'MIX 2',
        sub: 'Arctic Monkeys...',
        badgeColor: Color(0xFF1E64C8),
        color1: Color(0xFF0d1b2a),
        color2: Color(0xFF1a3a2a),
      ),
      const _MixData(
        label: 'MIX 3',
        sub: 'The Weeknd, Drake...',
        badgeColor: Color(0x66CCCCCC),
        color1: Color(0xFF2d1b2e),
        color2: Color(0xFF6b2d4a),
      ),
    ];

    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: mixes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final m = mixes[i];
          return GestureDetector(
            onTap: () => _navigateToProfile(context),
            child: SizedBox(
              width: 148,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 148,
                        height: 148,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: LinearGradient(
                            colors: [m.color1, m.color2],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: m.badgeColor,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(4),
                              bottomRight: Radius.circular(4),
                            ),
                          ),
                          child: Text(
                            m.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    m.sub,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF999999),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ManagedTracksSection extends StatelessWidget {
  const _ManagedTracksSection({
    required this.tracks,
    required this.onManageTap,
  });

  final List<ManagedTrack> tracks;
  final ValueChanged<ManagedTrack> onManageTap;

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          'No managed tracks remaining.',
          style: TextStyle(color: Color(0xFF999999), fontSize: 13),
        ),
      );
    }

    return Column(
      children: tracks.map((track) {
        return Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${track.genreName ?? 'Unknown genre'} • ${track.visibility.displayLabel}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => onManageTap(track),
                    child: const Text('Manage'),
                  ),
                ],
              ),
            ),
            const Divider(
              color: Color(0xFF1A1A1A),
              height: 1,
              indent: 14,
              endIndent: 14,
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _GenreChips extends StatelessWidget {
  final List<String> genres;
  final String selected;
  final ValueChanged<String> onSelect;

  const _GenreChips({
    required this.genres,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: genres.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final g = genres[i];
          final active = g == selected;
          return GestureDetector(
            onTap: () => onSelect(g),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active
                      ? const Color(0xFFFF5500)
                      : const Color(0xFF444444),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                g,
                style: TextStyle(
                  color:
                      active ? const Color(0xFFFF5500) : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TrendingTracks extends StatelessWidget {
  const _TrendingTracks();

  @override
  Widget build(BuildContext context) {
    final tracks = [
      Track(
        id: '1',
        title: 'Bunker - Balthazar',
        artist: 'Balthazar',
        audioUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        artworkUrl: 'https://picsum.photos/200?1',
        handle: 'balthazar',
      ),
      Track(
        id: '2',
        title: 'Take It or Leave It',
        artist: 'Cage the Elephant',
        audioUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
        artworkUrl: 'https://picsum.photos/200?2',
        handle: 'cagetheelephant',
      ),
      Track(
        id: '3',
        title: 'Take Me Out',
        artist: 'Franz Ferdinand',
        audioUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
        artworkUrl: 'https://picsum.photos/200?3',
        handle: 'franzferdinand',
      ),
    ];

    return Column(
      children: List.generate(
        tracks.length,
        (i) => Column(
          children: [
            // ← مرر الـ queue كلها لكل track
            TrackRow(track: tracks[i], queue: tracks),
            if (i < tracks.length - 1)
              const Divider(
                color: Color(0xFF1A1A1A),
                height: 1,
                indent: 14,
                endIndent: 14,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom nav ────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Home',
      ),
      _NavItem(
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view,
        label: 'Feed',
      ),
      _NavItem(
        icon: Icons.search,
        activeIcon: Icons.search,
        label: 'Search',
      ),
      _NavItem(
        icon: Icons.library_music_outlined,
        activeIcon: Icons.library_music,
        label: 'Library',
      ),
      _NavItem(
        icon: Icons.equalizer_outlined,
        activeIcon: Icons.equalizer,
        label: 'Upgrade',
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Color(0xFF1F1F1F))),
      ),
      child: Row(
        children: List.generate(
          items.length,
          (i) => Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      selected == i ? items[i].activeIcon : items[i].icon,
                      color: selected == i
                          ? Colors.white
                          : const Color(0xFF555555),
                      size: 22,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      items[i].label,
                      style: TextStyle(
                        color: selected == i
                            ? Colors.white
                            : const Color(0xFF555555),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────

class _AlbumData {
  final String label, sub, handle, topText;
  final Color color1, color2;

  const _AlbumData({
    required this.label,
    required this.sub,
    required this.handle,
    required this.topText,
    required this.color1,
    required this.color2,
  });
}

class _MixData {
  final String label, sub;
  final Color badgeColor, color1, color2;

  const _MixData({
    required this.label,
    required this.sub,
    required this.badgeColor,
    required this.color1,
    required this.color2,
  });
}

class _NavItem {
  final IconData icon, activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,


    
  });
}