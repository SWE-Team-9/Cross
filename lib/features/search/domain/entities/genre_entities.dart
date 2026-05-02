// lib/features/search/domain/entities/genre_entities.dart
//
// Domain entities for the genre page.
// AlbumEntity and GenreProfileEntity are new.
// GenrePageData aggregates everything the GenreCubit needs.
//
// NOTE: Track already has a `genre` field added in core/models/track.dart
//       (see patch note at the bottom of this file).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:equatable/equatable.dart';

import '../../../../core/models/track.dart';
import 'search_entities.dart';    // PlaylistEntity

// ── Album ─────────────────────────────────────────────────────────────────────

class AlbumEntity extends Equatable {
  final String id;
  final String title;
  final String artistName;
  final String artworkUrl;
  final int    trackCount;
  final int    releaseYear;

  const AlbumEntity({
    required this.id,
    required this.title,
    required this.artistName,
    required this.artworkUrl,
    this.trackCount  = 0,
    this.releaseYear = 0,
  });

  @override
  List<Object?> get props =>
      [id, title, artistName, artworkUrl, trackCount, releaseYear];
}

// ── Genre Profile ─────────────────────────────────────────────────────────────

class GenreProfileEntity extends Equatable {
  final String id;
  final String username;
  final String displayName;
  final String avatarUrl;
  final bool   isVerified;

  const GenreProfileEntity({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    this.isVerified = false,
  });

  @override
  List<Object?> get props =>
      [id, username, displayName, avatarUrl, isVerified];
}

// ── Genre Page Data ───────────────────────────────────────────────────────────
// Aggregates all sections needed to render the genre page.

class GenrePageData {
  final String                   headerImageUrl;
  final List<Track>              trending;
  final Track?                   introducing;
  final List<Track>              introducingExtras;
  final List<PlaylistEntity>     playlists;
  final List<AlbumEntity>        albums;
  final List<GenreProfileEntity> profiles;
  final List<Track>              discoverMore;
  final Set<String>              followingIds;   // IDs the current user follows

  const GenrePageData({
    this.headerImageUrl    = '',
    this.trending          = const [],
    this.introducing,
    this.introducingExtras = const [],
    this.playlists         = const [],
    this.albums            = const [],
    this.profiles          = const [],
    this.discoverMore      = const [],
    this.followingIds      = const {},
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// PATCH NOTE — core/models/track.dart
// ─────────────────────────────────────────────────────────────────────────────
// Add the `genre` field to your Track model so the datasource can store it
// and the cubit can filter by it.
//
// class Track {
//   ...
//   final String? genre;      // ← ADD THIS
//
//   const Track({
//     ...
//     this.genre,             // ← ADD THIS
//   });
//
//   Track copyWith({ ..., String? genre }) =>
//       Track( ..., genre: genre ?? this.genre );
// }
// ─────────────────────────────────────────────────────────────────────────────