// ─────────────────────────────────────────────────────────────────────────────
//  feed_item.dart  —  Domain Entity
//  Clean entity, no JSON logic, no external dependencies.
//  Matches data from:
//    GET /api/v1/feed                  (activity feed)
//    GET /api/v1/discovery/search      (global search)
//    GET /api/v1/discovery/trending    (trending tracks)
//    GET /api/v1/discovery/resolve     (permalink resolver)
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
  /// Direct audio URL returned by the feed endpoint
  final String? audioUrl;

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
    this.audioUrl,
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
    String? audioUrl,
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
      audioUrl: audioUrl ?? this.audioUrl,
    );
  }
}

// ─── Activity Feed Item ───────────────────────────────────────────────────────
// Matches GET /api/v1/feed → data[]

class FeedItem {
  final String activityId;   // feed_id from API
  /// 'UPLOAD' | 'REPOST' | 'LIKE'  — from action_type
  final String action;
  final String timeAgo;      // derived from created_at
  final String? createdAt;   // raw ISO timestamp from API
  final FeedActor actor;
  final FeedTrack track;

  const FeedItem({
    required this.activityId,
    required this.action,
    required this.timeAgo,
    this.createdAt,
    required this.actor,
    required this.track,
  });

  FeedItem copyWith({FeedTrack? track}) {
    return FeedItem(
      activityId: activityId,
      action: action,
      timeAgo: timeAgo,
      createdAt: createdAt,
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
  final int totalPages;

  const FeedPage({
    required this.items,
    required this.page,
    required this.hasMore,
    required this.totalItems,
    required this.totalPages,
  });
}

// ─── Search Result Entities ───────────────────────────────────────────────────
// Matches GET /api/v1/discovery/search → data{}

class SearchUserResult {
  final String id;
  final String displayName;
  final String? handle;
  final String? avatarUrl;

  const SearchUserResult({
    required this.id,
    required this.displayName,
    this.handle,
    this.avatarUrl,
  });
}

class SearchTrackResult {
  final String id;
  final String title;
  final String? genre;
  final String? coverArtUrl;
  final String? artistName;

  const SearchTrackResult({
    required this.id,
    required this.title,
    this.genre,
    this.coverArtUrl,
    this.artistName,
  });
}

class SearchPlaylistResult {
  final String id;
  final String title;
  final String? coverArtUrl;

  const SearchPlaylistResult({
    required this.id,
    required this.title,
    this.coverArtUrl,
  });
}

class SearchResults {
  final List<SearchUserResult> users;
  final List<SearchTrackResult> tracks;
  final List<SearchPlaylistResult> playlists;
  final int currentPage;
  final int totalResults;
  final int totalPages;

  const SearchResults({
    required this.users,
    required this.tracks,
    required this.playlists,
    required this.currentPage,
    required this.totalResults,
    required this.totalPages,
  });
}

// ─── Trending Entity ──────────────────────────────────────────────────────────
// Matches GET /api/v1/discovery/trending

class TrendingTrack {
  final String id;
  final String title;
  final String? genre;
  final String? coverArtUrl;
  final String? artistName;
  final String? artistHandle;
  final int playsCount;
  final int likesCount;
  final int repostsCount;

  const TrendingTrack({
    required this.id,
    required this.title,
    this.genre,
    this.coverArtUrl,
    this.artistName,
    this.artistHandle,
    required this.playsCount,
    required this.likesCount,
    required this.repostsCount,
  });
}

// ─── Resolve Result ───────────────────────────────────────────────────────────
// Matches GET /api/v1/discovery/resolve

class ResolveResult {
  final String type;       // 'TRACK' | 'USER' | 'PLAYLIST'
  final String resourceId;
  final String? ownerId;

  const ResolveResult({
    required this.type,
    required this.resourceId,
    this.ownerId,
  });
}