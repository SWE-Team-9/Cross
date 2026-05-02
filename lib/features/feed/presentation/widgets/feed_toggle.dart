// ─────────────────────────────────────────────────────────────────────────────
//  feed_toggle.dart  —  Discover / Following Toggle
//  Matches SoundCloud's pill toggle at the top of the feed.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../bloc/feed_state.dart';

class FeedToggle extends StatelessWidget {
  final FeedTab selected;
  final ValueChanged<FeedTab> onChanged;

  const FeedToggle({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: FeedTab.values
            .map((tab) => _Tab(
                  label: tab.label,
                  isActive: selected == tab,
                  onTap: () => onChanged(tab),
                ))
            .toList(),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2A2A2A) : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? Colors.white : const Color(0xFF888888),
          ),
        ),
      ),
    );
  }
}
