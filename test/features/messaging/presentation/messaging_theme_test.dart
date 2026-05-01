import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/messaging/presentation/messaging_theme.dart';

void main() {
  group('MessagingTheme', () {
    test('exposes expected color constants', () {
      expect(MessagingTheme.background, Colors.black);
      expect(MessagingTheme.surface, const Color(0xFF121212));
      expect(MessagingTheme.surfaceAlt, const Color(0xFF1A1A1A));
      expect(MessagingTheme.border, Colors.white10);
      expect(MessagingTheme.accent, const Color(0xFFFF5500));
      expect(MessagingTheme.accentSoft, const Color(0x33FF5500));
      expect(MessagingTheme.textPrimary, Colors.white);
      expect(MessagingTheme.textSecondary, Colors.white70);
      expect(MessagingTheme.textMuted, Colors.white54);
    });
  });
}
