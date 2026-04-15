import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import '../../../../app/router.dart';

class MockFeedPage extends StatelessWidget {
  const MockFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tracks = _mockTracks;

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];
          return _FeedTrackCard(track: track);
        },
      ),
      bottomNavigationBar: _BottomNav(
        selected: 1,
        onTap: (i) {
          switch (i) {
            case 0:
              context.goNamed('home');
              break;
            case 1:
              break;
            case 2:
              context.goNamed('search');
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

class _FeedTrackCard extends StatelessWidget {
  final Track track;

  const _FeedTrackCard({required this.track});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        track.artworkUrl != null
            ? Image.network(
                track.artworkUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.black),
              )
            : Container(color: Colors.black),
        Container(color: Colors.black.withValues(alpha: 0.4)),
        const Center(
          child: Icon(
            Icons.play_circle_fill,
            color: Colors.white,
            size: 80,
          ),
        ),
        Positioned(
          bottom: 40,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // 🔥 Track info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        track.artist,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // 🔥 PLAY BUTTON (ONLY CHANGE HERE)
                GestureDetector(
                  onTap: () {
                    final playerService = GetIt.I<AudioPlayerService>();
                    final playerCubit = context.read<PlayerCubit>();

                    // 🔥 Hide mini player
                    playerCubit.hideMiniPlayer();

                    // 🔥 Play
                    playerService.playFromContext(
                      tracks: [track],
                      startIndex: 0,
                      source: "feed",
                    );

                    playerCubit.play(track);

                    // 🔥 OPEN FULL PLAYER
                    playerCubit.openFullPlayer();
                    Navigator.pushNamed(context, AppRoutes.player);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────

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
// 🔥 MOCK DATA

final List<Track> _mockTracks = [
  Track(
    id: '1',
    title: 'Feed Track 1',
    artist: 'Artist 1',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    artworkUrl: null,
  ),
  Track(
    id: '2',
    title: 'Feed Track 2',
    artist: 'Artist 2',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    artworkUrl: null,
  ),
  Track(
    id: '3',
    title: 'Feed Track 3',
    artist: 'Artist 3',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    artworkUrl: null,
  ),
];
