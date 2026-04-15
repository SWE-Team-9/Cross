import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/core/widgets/track_row.dart';

class MockSearchPage extends StatefulWidget {
  const MockSearchPage({super.key});

  @override
  State<MockSearchPage> createState() => _MockSearchPageState();
}

class _MockSearchPageState extends State<MockSearchPage> {
  final TextEditingController _controller = TextEditingController();

  List<Track> _results = [];
  final List<Track> _allTracks = _mockTracks;

  void _onSearch(String query) {
    final filtered = _allTracks.where((track) {
      return track.title.toLowerCase().contains(query.toLowerCase()) ||
          track.artist.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      _results = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: TextField(
          controller: _controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Search tracks...",
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
          ),
          onChanged: _onSearch,
        ),
      ),
      body: _results.isEmpty
          ? const Center(
              child: Text(
                "Start typing to search",
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final track = _results[index];

                return TrackRow(
                  track: track,
                  queue: _results,
                  source: "search", // ✅ CRITICAL FIX
                );
              },
            ),
      bottomNavigationBar: _BottomNav(
        selected: 2,
        onTap: (i) {
          switch (i) {
            case 0:
              context.goNamed('home');
              break;
            case 1:
              context.goNamed('feed');
              break;
            case 2:
              break;
            case 3:
              context.goNamed('library');
              break;
            case 4:
              context.goNamed('upgrade');
              break;
          }
        },
      ),
    );
  }
}

// ─────────────────────────────
// 🔥 NAV BAR (reuse same)

class _BottomNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(Icons.home_outlined, Icons.home, 'Home'),
      _NavItem(Icons.grid_view_outlined, Icons.grid_view, 'Feed'),
      _NavItem(Icons.search, Icons.search, 'Search'),
      _NavItem(Icons.library_music_outlined, Icons.library_music, 'Library'),
      _NavItem(Icons.equalizer_outlined, Icons.equalizer, 'Upgrade'),
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

class _NavItem {
  final IconData icon, activeIcon;
  final String label;

  const _NavItem(this.icon, this.activeIcon, this.label);
}

// ─────────────────────────────
// 🔥 MOCK DATA (reuse same)

final List<Track> _mockTracks = [
  Track(
    id: '1',
    title: 'Feed Track 1',
    artist: 'Artist 1',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
  ),
  Track(
    id: '2',
    title: 'Chill Vibes',
    artist: 'DJ Cool',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
  ),
  Track(
    id: '3',
    title: 'Workout Mix',
    artist: 'Gym Hero',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
  ),
];
