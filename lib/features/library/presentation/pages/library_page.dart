import 'package:flutter/material.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/recently-played/presentation/widgets/recently_played_row.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            // 🔹 Top spacing
            const SizedBox(height: 12),

            // 🔹 Library options (like SoundCloud)
            _LibraryItem(title: 'Your likes'),
            _LibraryItem(title: 'Playlists'),
            _LibraryItem(title: 'Albums'),
            _LibraryItem(title: 'Following'),
            _LibraryItem(title: 'Stations'),
            _LibraryItem(title: 'Your insights'),
            _LibraryItem(title: 'Your uploads'),

            const SizedBox(height: 20),

            // =============================
            // 🔥 Recently Played (YOUR FEATURE)
            // =============================
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

            RecentlyPlayedRow(
              tracks: [
                Track(
                  id: '1',
                  title: 'Track 1',
                  artist: 'Artist 1',
                  audioUrl:
                      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
                  artworkUrl: 'https://picsum.photos/200?1',
                ),
                Track(
                  id: '2',
                  title: 'Track 2',
                  artist: 'Artist 2',
                  audioUrl:
                      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
                  artworkUrl: 'https://picsum.photos/200?2',
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 🔹 Placeholder for next feature (optional later)
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
    );
  }
}

// 🔹 Reusable row item (matches SoundCloud list style)
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
