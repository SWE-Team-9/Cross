// lib/features/search/presentation/widgets/search_empty_widget.dart

import 'package:flutter/material.dart';

/// Shown when the search succeeded but returned zero results.
class SearchEmptyWidget extends StatelessWidget {
  final String query;

  const SearchEmptyWidget({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, color: Colors.white24, size: 52),
          const SizedBox(height: 12),
          Text(
            'No results for "$query"',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try different keywords or check your spelling',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
