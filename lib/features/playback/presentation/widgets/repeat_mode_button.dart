import 'package:flutter/material.dart';

import 'package:soundcloud_clone/core/models/player_state.dart';

class RepeatModeButton extends StatelessWidget {
  final AppRepeatMode mode;
  final ValueChanged<AppRepeatMode> onChanged;
  final double iconSize;
  final EdgeInsetsGeometry padding;
  final bool showOptions;

  const RepeatModeButton({
    super.key,
    required this.mode,
    required this.onChanged,
    this.iconSize = 28,
    this.padding = const EdgeInsets.all(8),
    this.showOptions = true,
  });

  @override
  Widget build(BuildContext context) {
    final active = mode != AppRepeatMode.off;
    final color = active ? const Color(0xFFFF5500) : Colors.white60;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _handleTap(context),
      child: Padding(
        padding: padding,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: Icon(
            _iconFor(mode),
            key: ValueKey(mode),
            color: color,
            size: iconSize,
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    if (!showOptions || Navigator.maybeOf(context) == null) {
      onChanged(_nextMode(mode));
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                for (final value in AppRepeatMode.values)
                  ListTile(
                    leading: Icon(
                      _iconFor(value),
                      color: value == mode
                          ? const Color(0xFFFF5500)
                          : Colors.white70,
                    ),
                    title: Text(
                      _labelFor(value),
                      style: TextStyle(
                        color: value == mode
                            ? const Color(0xFFFF5500)
                            : Colors.white,
                        fontWeight:
                            value == mode ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                    trailing: value == mode
                        ? const Icon(
                            Icons.check,
                            color: Color(0xFFFF5500),
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      onChanged(value);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static IconData _iconFor(AppRepeatMode mode) {
    switch (mode) {
      case AppRepeatMode.off:
        return Icons.repeat_outlined;
      case AppRepeatMode.one:
        return Icons.repeat_one;
      case AppRepeatMode.all:
        return Icons.repeat;
    }
  }

  static AppRepeatMode _nextMode(AppRepeatMode mode) {
    switch (mode) {
      case AppRepeatMode.off:
        return AppRepeatMode.one;
      case AppRepeatMode.one:
        return AppRepeatMode.all;
      case AppRepeatMode.all:
        return AppRepeatMode.off;
    }
  }

  static String _labelFor(AppRepeatMode mode) {
    switch (mode) {
      case AppRepeatMode.off:
        return "Don't repeat";
      case AppRepeatMode.one:
        return 'Repeat current track';
      case AppRepeatMode.all:
        return 'Repeat queue';
    }
  }
}
