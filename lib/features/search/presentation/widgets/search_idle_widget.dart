// lib/features/search/presentation/widgets/search_idle_widget.dart

import 'package:flutter/material.dart';

class SearchIdleWidget extends StatelessWidget {
  const SearchIdleWidget({super.key});

  static const _genres = [
    _Genre('Hip Hop & Rap', Color(0xFF7C3AED), Icons.mic_rounded),
    _Genre('Electronic', Color(0xFFDB2777), Icons.equalizer_rounded),
    _Genre('Pop', Color(0xFFD97706), Icons.star_rounded),
    _Genre('R&B', Color(0xFF0891B2), Icons.favorite_rounded),
    _Genre('Chill', Color(0xFF0D9488), Icons.self_improvement_rounded),
    _Genre('Party', Color(0xFFEA580C), Icons.celebration_rounded),
    _Genre('Workout', Color(0xFF16A34A), Icons.fitness_center_rounded),
    _Genre('Techno', Color(0xFFBE185D), Icons.graphic_eq_rounded),
    _Genre('House', Color(0xFFDC2626), Icons.speaker_rounded),
    _Genre('Feel Good', Color(0xFFCA8A04), Icons.sentiment_very_satisfied_rounded),
    _Genre('Healing Era', Color(0xFF2563EB), Icons.spa_rounded),
    _Genre('At Home', Color(0xFF7C3AED), Icons.home_rounded),
    _Genre('Study', Color(0xFFDB2777), Icons.menu_book_rounded),
    _Genre('Folk', Color(0xFF92400E), Icons.forest_rounded),
    _Genre('Indie', Color(0xFF1D4ED8), Icons.music_note_rounded),
    _Genre('Soul', Color(0xFF0F766E), Icons.volunteer_activism_rounded),
    _Genre('Country', Color(0xFFB45309), Icons.agriculture_rounded),
    _Genre('Latin', Color(0xFFBE185D), Icons.local_fire_department_rounded),
    _Genre('Rock', Color(0xFF374151), Icons.bolt_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Text(
              'Vibes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.9,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) => _GenreCard(genre: _genres[i]),
              childCount: _genres.length,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Genre card ────────────────────────────────────────────────────────────────

class _GenreCard extends StatelessWidget {
  final _Genre genre;
  const _GenreCard({required this.genre});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Material(
        color: genre.color,
        child: InkWell(
          onTap: () {}, // لاحقاً navigate للـ genre
          child: Stack(
            children: [
              // خطوط زخرفية زي SoundCloud
              Positioned(
                right: -15,
                bottom: -15,
                child: Opacity(
                  opacity: 0.15,
                  child: Icon(
                    genre.icon,
                    size: 90,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                right: 5,
                bottom: 5,
                child: Opacity(
                  opacity: 0.25,
                  child: Icon(
                    genre.icon,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
              // اسم الـ genre
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  genre.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    shadows: [
                      Shadow(
                        color: Colors.black38,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────

class _Genre {
  final String name;
  final Color color;
  final IconData icon;
  const _Genre(this.name, this.color, this.icon);
}