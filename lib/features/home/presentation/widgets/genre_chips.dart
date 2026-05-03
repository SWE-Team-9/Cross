import 'package:flutter/material.dart';
import 'genre_color_utils.dart';

/// Horizontally scrollable genre filter chips.
/// Each chip adopts the accent color mapped from [genreAccentColor].
/// The active chip glows; inactive chips show a tinted border and label.
class GenreChips extends StatelessWidget {
  const GenreChips({
    super.key,
    required this.genres,
    required this.selected,
    required this.onSelect,
  });

  final List<String> genres;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: genres.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final genre = genres[index];
          final active = genre == selected;
          final color = genreAccentColor(genre);

          return GestureDetector(
            onTap: () => onSelect(genre),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: active ? color : color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active ? color : color.withValues(alpha: 0.35),
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.45),
                          blurRadius: 12,
                          spreadRadius: -2,
                        )
                      ]
                    : const [],
              ),
              alignment: Alignment.center,
              child: Text(
                genre,
                style: TextStyle(
                  color: active ? Colors.white : color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}