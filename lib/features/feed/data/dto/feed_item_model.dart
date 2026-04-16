// ─────────────────────────────────────────────────────────────────────────────
//  feed_item_model.dart  —  Data Model
//  Converts raw API JSON → domain entities.
//  JSON shapes match exactly:
//    Module 4 → GET /api/v1/users/{userId}/tracks
//    Module 3 → GET /api/v1/social/suggestions
// ─────────────────────────────────────────────────────────────────────────────

import '../../domain/entities/feed_item.dart';

// ─── Actor Model ─────────────────────────────────────────────────────────────

class FeedActorModel extends FeedActor {
  const FeedActorModel({
    required super.userId,
    required super.displayName,
    required super.handle,
    super.avatarUrl,
    required super.verified,
  });

  factory FeedActorModel.fromJson(Map<String, dynamic> json) {
    return FeedActorModel(
      userId: json['userId'] as String? ?? json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ??
          json['display_name'] as String? ??
          '',
      handle: json['handle'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
      verified: json['verified'] as bool? ?? false,
    );
  }
}

// ─── Stats Model ─────────────────────────────────────────────────────────────

class TrackStatsModel extends TrackStats {
  const TrackStatsModel({
    required super.likesCount,
    required super.commentsCount,
    required super.repostsCount,
    required super.playsCount,
  });

  factory TrackStatsModel.fromJson(Map<String, dynamic> json) {
    return TrackStatsModel(
      likesCount: json['likesCount'] as int? ?? 0,
      commentsCount: json['commentsCount'] as int? ?? 0,
      repostsCount: json['repostsCount'] as int? ?? 0,
      playsCount: json['playsCount'] as int? ?? 0,
    );
  }
}

// ─── UserState Model ─────────────────────────────────────────────────────────

class TrackUserStateModel extends TrackUserState {
  const TrackUserStateModel({
    required super.liked,
    required super.reposted,
    required super.inLibrary,
  });

  factory TrackUserStateModel.fromJson(Map<String, dynamic> json) {
    return TrackUserStateModel(
      liked: json['liked'] as bool? ?? false,
      reposted: json['reposted'] as bool? ?? false,
      inLibrary: json['inLibrary'] as bool? ?? false,
    );
  }

  /// Default state when API doesn't return userState yet
  factory TrackUserStateModel.defaults() {
    return const TrackUserStateModel(
      liked: false,
      reposted: false,
      inLibrary: false,
    );
  }
}

// ─── Track Model ─────────────────────────────────────────────────────────────

class FeedTrackModel extends FeedTrack {
  const FeedTrackModel({
    required super.trackId,
    required super.title,
    required super.slug,
    required super.durationMs,
    required super.status,
    required super.visibility,
    super.coverArtUrl,
    required super.genre,
    super.waveformData,
    required super.artist,
    required super.stats,
    required super.userState,
  });

  /// Parses track from Module 4 response shape:
  /// GET /api/v1/users/{userId}/tracks → tracks[]
  factory FeedTrackModel.fromJson(Map<String, dynamic> json) {
    // waveformData can be null or a list of numbers
    List<double>? waveform;
    if (json['waveformData'] != null) {
      waveform = (json['waveformData'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
    }

    // artist can be nested object or flat fields
    final artistJson = json['artist'] as Map<String, dynamic>?;

    return FeedTrackModel(
      trackId: json['trackId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      durationMs: json['durationMs'] as int? ?? 0,
      status: json['status'] as String? ?? 'FINISHED',
      visibility: json['visibility'] as String? ?? 'PUBLIC',
      coverArtUrl: json['coverArtUrl'] as String?,
      genre: json['genre'] as String? ?? '',
      waveformData: waveform,
      artist: artistJson != null
          ? FeedActorModel.fromJson({
              'userId': artistJson['id'],
              'displayName': artistJson['displayName'],
              'handle': artistJson['handle'],
              'avatarUrl': artistJson['avatarUrl'],
              'verified': artistJson['verified'] ?? false,
            })
          : const FeedActorModel(
              userId: '',
              displayName: '',
              handle: '',
              verified: false,
            ),
      stats: json['stats'] != null
          ? TrackStatsModel.fromJson(json['stats'] as Map<String, dynamic>)
          : const TrackStatsModel(
              likesCount: 0,
              commentsCount: 0,
              repostsCount: 0,
              playsCount: 0,
            ),
      userState: json['userState'] != null
          ? TrackUserStateModel.fromJson(
              json['userState'] as Map<String, dynamic>)
          : TrackUserStateModel.defaults(),
    );
  }
}

// ─── FeedItem Model ──────────────────────────────────────────────────────────

class FeedItemModel extends FeedItem {
  const FeedItemModel({
    required super.activityId,
    required super.action,
    required super.timeAgo,
    required super.actor,
    required super.track,
  });

  factory FeedItemModel.fromJson(Map<String, dynamic> json) {
    return FeedItemModel(
      activityId: json['activityId'] as String? ?? '',
      action: json['action'] as String? ?? 'posted a track',
      timeAgo: json['timeAgo'] as String? ?? '',
      actor: FeedActorModel.fromJson(
        json['actor'] as Map<String, dynamic>? ?? {},
      ),
      track: FeedTrackModel.fromJson(
        json['track'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

// ─── FeedPage Model ──────────────────────────────────────────────────────────

class FeedPageModel extends FeedPage {
  const FeedPageModel({
    required super.items,
    required super.page,
    required super.hasMore,
    required super.totalItems,
  });

  /// Parses paginated response from Module 4:
  /// { page, limit, totalTracks, tracks: [...] }
  factory FeedPageModel.fromJson(Map<String, dynamic> json, int pageSize) {
    final rawItems = json['tracks'] as List<dynamic>? ?? [];
    final items = rawItems
        .map((e) => FeedItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final page = json['page'] as int? ?? 1;
    final totalItems = json['totalTracks'] as int? ?? items.length;
    final hasMore = page * pageSize < totalItems;

    return FeedPageModel(
      items: items,
      page: page,
      hasMore: hasMore,
      totalItems: totalItems,
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// "21600"  →  "21.6K"
/// "1200000" → "1.2M"
String formatCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}
