import 'package:flutter/material.dart';

/// Maps a genre label to its accent color used across the home screen.
Color genreAccentColor(String genre) {
  final key = genre.trim().toUpperCase();
  const _map = <String, Color>{
    'ELECTRONIC':   Color(0xFFFF5500),
    'HIP HOP & RAP': Color(0xFFBD00FF),
    'POP':          Color(0xFFFF007A),
    'R&B & SOUL':   Color(0xFF00C2FF),
    'DANCEHALL':    Color(0xFF00E676),
    'LATIN':        Color(0xFFFF9100),
    'ROCK':         Color(0xFFFF1744),
    'CLASSICAL':    Color(0xFF64B5F6),
    'COUNTRY':      Color(0xFFFFD740),
    'JAZZ':         Color(0xFF69F0AE),
    'METAL':        Color(0xFF90A4AE),
    'REGGAE':       Color(0xFF00E676),
    'SOUNDCLOUD':   Color(0xFFFF5500),
    'ALL':          Color(0xFFFF5500),
  };
  for (final entry in _map.entries) {
    if (key.contains(entry.key)) return entry.value;
  }
  return const Color(0xFFFF5500);
}