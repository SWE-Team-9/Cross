// ─────────────────────────────────────────────────────────────────────────────
//  bottom_nav_bar.dart  —  Shared Bottom Navigation Bar
//  Used by: MockHomePage, FeedPage (and any future screen)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavBar extends StatelessWidget {
  static const double minHeight = 58;

  final int selected;
  final ValueChanged<int>? onTap; // optional — uses default routing if null

  const BottomNavBar({
    super.key,
    required this.selected,
    this.onTap,
  });

  static const _items = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    _NavItem(
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view,
        label: 'Feed'),
    _NavItem(icon: Icons.search, activeIcon: Icons.search, label: 'Search'),
    _NavItem(
        icon: Icons.library_music_outlined,
        activeIcon: Icons.library_music,
        label: 'Library'),
    _NavItem(
        icon: Icons.equalizer_outlined,
        activeIcon: Icons.equalizer,
        label: 'Upgrade'),
  ];

  static const _routes = ['/home', '/feed', '/search', '/library', '/upgrade'];

  void _handleTap(BuildContext context, int index) {
    if (onTap != null) {
      onTap!(index);
      return;
    }
    // Default: navigate via go_router
    if (index < _routes.length) {
      context.go(_routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: minHeight),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Color(0xFF1F1F1F))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(
            _items.length,
            (i) => Expanded(
              child: GestureDetector(
                onTap: () => _handleTap(context, i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected == i ? _items[i].activeIcon : _items[i].icon,
                        color: selected == i
                            ? Colors.white
                            : const Color(0xFF555555),
                        size: 23,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _items[i].label,
                        style: TextStyle(
                          color: selected == i
                              ? Colors.white
                              : const Color(0xFF555555),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
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
  const _NavItem(
      {required this.icon, required this.activeIcon, required this.label});
}
