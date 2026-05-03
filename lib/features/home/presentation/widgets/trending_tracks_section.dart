import 'package:flutter/material.dart';

import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/widgets/track_row.dart';
import 'package:soundcloud_clone/features/home/domain/entities/home_content.dart';
import 'genre_color_utils.dart';

/// The "Trending now" track list.
/// Wraps tracks in an animated gradient container whose color reacts to
/// [selectedGenre] — matching the SoundCloud ambient background effect.
class TrendingTracksSection extends StatelessWidget {
  const TrendingTracksSection({
    super.key,
    required this.loading,
    required this.error,
    required this.tracks,
    required this.selectedGenre,
  });

  final bool loading;
  final String? error;
  final List<Track> tracks;
  final String selectedGenre;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF5500)),
        ),
      );
    }

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 4),
        child: Text(error!, style: const TextStyle(color: Colors.white54)),
      );
    }

    if (tracks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 4),
        child: Text(
          selectedGenre == HomeContent.topLikedGenre
              ? 'No trending tracks available yet'
              : 'No tracks found for this genre',
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }

    final visibleTracks = tracks.take(5).toList(growable: false);
    final accentColor = genreAccentColor(selectedGenre);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accentColor.withOpacity(0.18),
              accentColor.withOpacity(0.07),
              Colors.transparent,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
          border: Border.all(
            color: accentColor.withOpacity(0.22),
          ),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Ambient glow blob — top-left corner
            Positioned(
              top: -24,
              left: -24,
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accentColor.withOpacity(0.32),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Track rows
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: visibleTracks
                    .map(
                      (track) => TrackRow(
                        track: track,
                        queue: visibleTracks,
                        source: 'home_trending',
                        showLikesCount: true,
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}