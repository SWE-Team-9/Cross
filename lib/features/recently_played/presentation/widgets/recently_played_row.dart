import 'package:flutter/material.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'recently_played_card.dart';

class RecentlyPlayedRow extends StatelessWidget {
  final List<Track> tracks;
  final VoidCallback? onSeeAll;
  final ValueChanged<Track>? onTrackTap;

  const RecentlyPlayedRow({
    super.key,
    required this.tracks,
    this.onSeeAll,
    this.onTrackTap,
  });

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 20, 14, 12),
          child: Row(
            children: [
              const Text(
                'Recently played',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),

              // Optional See All button
              if (onSeeAll != null)
                GestureDetector(
                  onTap: onSeeAll,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'See all',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Horizontal list
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: tracks.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return RecentlyPlayedCard(
                track: tracks[index],
                onTap: onTrackTap != null ? () => onTrackTap!(tracks[index]) : null,
              );
            },
          ),
        ),
      ],
    );
  }
}
