// ─────────────────────────────────────────────────────────────────────────────
//  feed_item.dart  —  Domain Entity
//  Clean entity, no JSON logic, no external dependencies.
//  Matches data from:
//    Module 4 → GET /api/v1/users/{userId}/tracks
//    Module 3 → GET /api/v1/social/suggestions
// ─────────────────────────────────────────────────────────────────────────────

class FeedActor {
  final String userId;
  final String displayName;
  final String handle;
  final String? avatarUrl;
  final bool verified;

  const FeedActor({
    required this.userId,
    required this.displayName,
    required this.handle,
    this.avatarUrl,
    required this.verified,
  });
}

class TrackStats {
  final int likesCount;
  final int commentsCount;
  final int repostsCount;
  final int playsCount;

  const TrackStats({
    required this.likesCount,
    required this.commentsCount,
    required this.repostsCount,
    required this.playsCount,
  });

  TrackStats copyWith({
    int? likesCount,
    int? commentsCount,
    int? repostsCount,
    int? playsCount,
  }) {
    return TrackStats(
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      repostsCount: repostsCount ?? this.repostsCount,
      playsCount: playsCount ?? this.playsCount,
    );
  }
}

class TrackUserState {
  final bool liked;
  final bool reposted;
  final bool inLibrary;

  const TrackUserState({
    required this.liked,
    required this.reposted,
    required this.inLibrary,
  });

  TrackUserState copyWith({
    bool? liked,
    bool? reposted,
    bool? inLibrary,
  }) {
    return TrackUserState(
      liked: liked ?? this.liked,
      reposted: reposted ?? this.reposted,
      inLibrary: inLibrary ?? this.inLibrary,
    );
  }
}

class FeedTrack {
  final String trackId;
  final String title;
  final String slug;
  final int durationMs;
  final String status;
  final String visibility;
  final String? coverArtUrl;
  final String genre;
  final List<double>? waveformData;
  final FeedActor artist;
  final TrackStats stats;
  final TrackUserState userState;

  const FeedTrack({
    required this.trackId,
    required this.title,
    required this.slug,
    required this.durationMs,
    required this.status,
    required this.visibility,
    this.coverArtUrl,
    required this.genre,
    this.waveformData,
    required this.artist,
    required this.stats,
    required this.userState,
  });

  /// "2:23" from durationMs
  String get formattedDuration {
    final totalSec = durationMs ~/ 1000;
    final m = totalSec ~/ 60;
    final s = (totalSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  FeedTrack copyWith({
    TrackStats? stats,
    TrackUserState? userState,
  }) {
    return FeedTrack(
      trackId: trackId,
      title: title,
      slug: slug,
      durationMs: durationMs,
      status: status,
      visibility: visibility,
      coverArtUrl: coverArtUrl,
      genre: genre,
      waveformData: waveformData,
      artist: artist,
      stats: stats ?? this.stats,
      userState: userState ?? this.userState,
    );
  }
}

class FeedItem {
  final String activityId;
  final String
      action; // 'posted a track' | 'reposted a track' | 'liked a track'
  final String timeAgo;
  final FeedActor actor;
  final FeedTrack track;

  const FeedItem({
    required this.activityId,
    required this.action,
    required this.timeAgo,
    required this.actor,
    required this.track,
  });

  FeedItem copyWith({FeedTrack? track}) {
    return FeedItem(
      activityId: activityId,
      action: action,
      timeAgo: timeAgo,
      actor: actor,
      track: track ?? this.track,
    );
  }
}

class FeedPage {
  final List<FeedItem> items;
  final int page;
  final bool hasMore;
  final int totalItems;

  const FeedPage({
    required this.items,
    required this.page,
    required this.hasMore,
    required this.totalItems,
  });
}
