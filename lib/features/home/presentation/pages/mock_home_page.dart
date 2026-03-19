import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/features/profile/presentation/routes/profile_routes.dart';

/// Mock Home page — matches the real SoundCloud home layout.
/// Used in Sprint 2 to test all navigation entry points.
/// Replace with real feed data in Sprint 4 (T4.11).
class MockHomePage extends StatefulWidget {
  const MockHomePage({super.key});

  @override
  State<MockHomePage> createState() => _MockHomePageState();
}

class _MockHomePageState extends State<MockHomePage> {
  static const _currentUserId = 'user_eyad';

  int _selectedTab = 0;
  String _selectedGenre = 'ELECTRONIC';

  final _genres = const [
    'ELECTRONIC', 'FOLK', 'HOUSE', 'TECHNO', 'POP', 'HIP-HOP',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(currentUserId: _currentUserId),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionHeader(title: 'More of what you like'),
                    const _RelatedTracksRow(),
                    const _SectionHeader(title: 'Mixed for Eyad Adel'),
                    _MixesRow(userId: _currentUserId),
                    const _SectionHeader(title: 'Trending by genre'),
                    _GenreChips(
                      genres: _genres,
                      selected: _selectedGenre,
                      onSelect: (g) => setState(() => _selectedGenre = g),
                    ),
                    const _TrendingTracks(),
                    const SizedBox(height: 16),
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
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String currentUserId;
  const _TopBar({required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 8),
      child: Row(
        children: [
          const Text(
            'Home',
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 12),
          
          const Text(
            'GET PRO',
            style: TextStyle(
                color: Color(0xFFFF5500),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: .5),
          ),
          const Spacer(),
          
          //  Profile Avatar 
          GestureDetector(
            onTap: () => ProfileRoutes.goToProfile(context, currentUserId),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFFFF5500),
              child: const Text('EY',
                  style: TextStyle(
                      color: Colors.white, 
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 8), // Add spacing after avatar
          
          _IconBtn(icon: Icons.cast, onTap: () {}),
          _IconBtn(
            icon: Icons.upload_outlined,
            onTap: () => context.push('/upload-picker'),
          ),
          _IconBtn(icon: Icons.mail_outline, onTap: () {}),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _IconBtn(
                icon: Icons.notifications_none,
                onTap: () => context.push('/notifications'),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5500),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                ),
              ),
            ],
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

// ── Section header ────────────────────────────────────────────────────────────

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
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ── Related tracks row ────────────────────────────────────────────────────────

class _RelatedTracksRow extends StatelessWidget {
  const _RelatedTracksRow();

  static const _cards = [
    _AlbumData(
      label: 'Related tracks: L...',
      sub: 'SoundCloud',
      userId: 'soundcloud_official',
      topText: 'Cage\nThe\nElephant',
      color1: Color(0xFF1a1a2e),
      color2: Color(0xFF16213e),
    ),
    _AlbumData(
      label: 'Related tracks: E...',
      sub: 'SoundCloud',
      userId: 'the_strokes',
      topText: 'THE\nStrokes',
      color1: Color(0xFF2d1b2e),
      color2: Color(0xFF8b1a1a),
    ),
    _AlbumData(
      label: 'Related tracks: A...',
      sub: 'SoundCloud',
      userId: 'arabic_artist',
      topText: 'ARABIC\nARTISTS',
      color1: Color(0xFF2a2a1a),
      color2: Color(0xFF1a2a1a),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 192,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: _cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final c = _cards[i];
          return GestureDetector(
            onTap: () => ProfileRoutes.goToProfile(context, c.userId),
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
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [c.color1, c.color2],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      c.topText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(c.label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  Text(c.sub,
                      style: const TextStyle(
                          color: Color(0xFF999999), fontSize: 12)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Mixes row ─────────────────────────────────────────────────────────────────

class _MixesRow extends StatelessWidget {
  final String userId;
  const _MixesRow({required this.userId});

  static const _mixes = [
    _MixData(
      label: 'MIX 1',
      sub: 'Balthazar, Cage the elephant, Cold ...',
      badgeColor: Color(0xFF8250C8),
      color1: Color(0xFF1a1a1a),
      color2: Color(0xFF2d1b2e),
    ),
    _MixData(
      label: 'MIX 2',
      sub: 'Arctic Monkeys, The Strokes, Tame Impala...',
      badgeColor: Color(0xFF1E64C8),
      color1: Color(0xFF0d1b2a),
      color2: Color(0xFF1a3a2a),
    ),
    _MixData(
      label: 'MIX 3',
      sub: 'The Weeknd, Drake, Frank Ocean, Post Malone...',
      badgeColor: Color(0x66CCCCCC),
      color1: Color(0xFF2d1b2e),
      color2: Color(0xFF6b2d4a),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: _mixes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final m = _mixes[i];
          return GestureDetector(
            onTap: () => ProfileRoutes.goToProfile(context, userId),
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
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
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
                              horizontal: 10, vertical: 5),
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
                                letterSpacing: 1),
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
                        color: Color(0xFF999999), fontSize: 11, height: 1.4),
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

// ── Genre chips ───────────────────────────────────────────────────────────────

class _GenreChips extends StatelessWidget {
  final List<String> genres;
  final String selected;
  final ValueChanged<String> onSelect;
  const _GenreChips(
      {required this.genres, required this.selected, required this.onSelect});

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
                  color: active ? const Color(0xFFFF5500) : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Trending tracks ───────────────────────────────────────────────────────────

class _TrendingTracks extends StatelessWidget {
  const _TrendingTracks();

  static const _tracks = [
    _TrackData(
      title: 'Bunker- Balthazar',
      artist: 'Balthazar',
      userId: 'balthazar_music',
      color1: Color(0xFFB5451B),
      color2: Color(0xFFFFD200),
    ),
    _TrackData(
      title: 'Take It or Leave It - Cage the elephant',
      artist: 'Cage the elephant',
      userId: 'cage_the_elephant',
      color1: Color(0xFF0d0d0d),
      color2: Color(0xFF1a1a3a),
    ),
    _TrackData(
      title: 'Take me out - Franz Ferdinand',
      artist: 'Franz Ferdinand',
      userId: 'franz_ferdinand',
      color1: Color(0xFF6C63FF),
      color2: Color(0xFF48CAE4),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(_tracks.length, (i) {
        final t = _tracks[i];
        return Column(
          children: [
            InkWell(
              onTap: () => ProfileRoutes.goToProfile(context, t.userId),
              splashColor: Colors.white10,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [t.color1, t.color2],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.title,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 3),
                          Text(t.artist,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Color(0xFF999999), fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.more_vert,
                          color: Color(0xFF666666), size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    // Related thumbnail on the right (matches screenshot)
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [t.color2, t.color1],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (i < _tracks.length - 1)
              const Divider(
                  color: Color(0xFF1A1A1A),
                  height: 1,
                  indent: 14,
                  endIndent: 14),
          ],
        );
      }),
    );
  }
}

// ── Bottom nav ────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.selected, required this.onTap});

  static const _items = [
    _NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Home'),
    _NavItem(
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view,
        label: 'Feed'),
    _NavItem(
        icon: Icons.search,
        activeIcon: Icons.search,
        label: 'Search'),
    _NavItem(
        icon: Icons.library_music_outlined,
        activeIcon: Icons.library_music,
        label: 'Library'),
    _NavItem(
        icon: Icons.equalizer_outlined,
        activeIcon: Icons.equalizer,
        label: 'Upgrade'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Color(0xFF1F1F1F))),
      ),
      child: Row(
        children: List.generate(_items.length, (i) {
          final item = _items[i];
          final active = selected == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      active ? item.activeIcon : item.icon,
                      color: active ? Colors.white : const Color(0xFF555555),
                      size: 22,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      style: TextStyle(
                        color:
                            active ? Colors.white : const Color(0xFF555555),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────

class _AlbumData {
  final String label, sub, userId, topText;
  final Color color1, color2;
  const _AlbumData({
    required this.label,
    required this.sub,
    required this.userId,
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

class _TrackData {
  final String title, artist, userId;
  final Color color1, color2;
  const _TrackData({
    required this.title,
    required this.artist,
    required this.userId,
    required this.color1,
    required this.color2,
  });
}

class _NavItem {
  final IconData icon, activeIcon;
  final String label;
  const _NavItem(
      {required this.icon, required this.activeIcon, required this.label});
}