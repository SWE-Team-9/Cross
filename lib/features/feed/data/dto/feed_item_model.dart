// ─────────────────────────────────────────────────────────────────────────────
//  feed_item_model.dart  —  Data Model
//
//  Feed response now includes all needed fields directly:
//    liked, reposted, likesCount, repostsCount, waveformData,
//    durationMs, coverArtUrl, genre, status, visibility
//
//  No extra API calls needed for interaction state.
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
      userId: json['id'] as String? ?? json['userId'] as String? ?? '',
      displayName: json['displayName'] as String? ??
          json['display_name'] as String? ??
          json['handle'] as String? ??
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
    super.audioUrl,
  });

  factory FeedTrackModel.fromJson(Map<String, dynamic> json) {
    List<double>? waveform;
    if (json['waveformData'] != null) {
      waveform = (json['waveformData'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
    }

    final artistJson = json['artist'] as Map<String, dynamic>?;

    // ── Stats: prefer nested 'stats' object, then fall back to flat fields ──
    final TrackStatsModel stats;
    if (json['stats'] != null) {
      stats = TrackStatsModel.fromJson(json['stats'] as Map<String, dynamic>);
    } else {
      stats = TrackStatsModel(
        likesCount: json['likesCount'] as int? ?? 0,
        commentsCount: json['commentsCount'] as int? ?? 0,
        repostsCount: json['repostsCount'] as int? ?? 0,
        playsCount: json['playsCount'] as int? ?? 0,
      );
    }

    // ── UserState: prefer nested 'userState', then flat liked/reposted ──────
    final TrackUserStateModel userState;
    if (json['userState'] != null) {
      userState = TrackUserStateModel.fromJson(
          json['userState'] as Map<String, dynamic>);
    } else {
      userState = TrackUserStateModel(
        liked: json['liked'] as bool? ?? false,
        reposted: json['reposted'] as bool? ?? false,
        inLibrary: json['inLibrary'] as bool? ?? false,
      );
    }

    return FeedTrackModel(
      trackId: json['id'] as String? ?? json['trackId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      durationMs: json['durationMs'] as int? ?? 0,
      status: json['status'] as String? ?? 'FINISHED',
      visibility: json['visibility'] as String? ?? 'PUBLIC',
      coverArtUrl:
          json['coverArtUrl'] as String? ?? json['cover_art_url'] as String?,
      genre: json['genre'] as String? ?? '',
      waveformData: waveform,
      audioUrl: json['audio_url'] as String? ?? json['audioUrl'] as String?,
      artist: artistJson != null
          ? FeedActorModel.fromJson(artistJson)
          : const FeedActorModel(
              userId: '', displayName: '', handle: '', verified: false),
      stats: stats,
      userState: userState,
    );
  }
}

// ─── FeedItem Model ──────────────────────────────────────────────────────────

class FeedItemModel extends FeedItem {
  const FeedItemModel({
    required super.activityId,
    required super.action,
    required super.timeAgo,
    super.createdAt,
    required super.actor,
    required super.track,
  });

  factory FeedItemModel.fromJson(Map<String, dynamic> json) {
    // ── Timestamp ────────────────────────────────────────────────────────────
    final activityAt = json['activityAt'] as String? ??
        json['publishedAt'] as String? ??
        json['createdAt'] as String? ??
        json['created_at'] as String?;

    // ── Action ───────────────────────────────────────────────────────────────
    final action = json['actionType'] as String? ??
        json['action_type'] as String? ??
        json['action'] as String? ??
        'POST';

    // ── Actor ────────────────────────────────────────────────────────────────
    final FeedActorModel actor;
    if (json['actor'] != null) {
      actor = FeedActorModel.fromJson(json['actor'] as Map<String, dynamic>);
    } else {
      final uploaderJson = json['uploader'] as Map<String, dynamic>?;
      final profileJson =
          uploaderJson?['profile'] as Map<String, dynamic>? ?? {};
      actor = FeedActorModel(
        userId: json['uploaderId'] as String? ?? '',
        displayName: profileJson['displayName'] as String? ??
            profileJson['display_name'] as String? ??
            profileJson['handle'] as String? ??
            '',
        handle: profileJson['handle'] as String? ?? '',
        avatarUrl: profileJson['avatarUrl'] as String? ??
            profileJson['avatar_url'] as String?,
        verified: profileJson['verified'] as bool? ?? false,
      );
    }

    // ── Track source: nested or flat ──────────────────────────────────────────
    final trackSource = json['track'] as Map<String, dynamic>? ?? json;

    // ── Artist on track ───────────────────────────────────────────────────────
    final artistJson = trackSource['artist'] as Map<String, dynamic>?;
    final trackArtist = artistJson != null
        ? FeedActorModel.fromJson(artistJson)
        : FeedActorModel(
            userId: trackSource['artistId'] as String? ??
                trackSource['uploaderId'] as String? ??
                actor.userId,
            displayName:
                trackSource['artistName'] as String? ?? actor.displayName,
            handle: trackSource['artistHandle'] as String? ?? actor.handle,
            avatarUrl: trackSource['artistAvatarUrl'] as String? ??
                actor.avatarUrl,
            verified: false,
          );

    // ── Waveform ──────────────────────────────────────────────────────────────
    List<double>? waveform;
    final rawWaveform = trackSource['waveformData'];
    if (rawWaveform is List) {
      waveform = rawWaveform.map((e) => (e as num).toDouble()).toList();
    }

    // ── Stats: flat fields from feed response ─────────────────────────────────
    final TrackStatsModel stats;
    if (trackSource['stats'] != null) {
      stats = TrackStatsModel.fromJson(
          trackSource['stats'] as Map<String, dynamic>);
    } else {
      stats = TrackStatsModel(
        likesCount: trackSource['likesCount'] as int? ?? 0,
        // commentsCount can be at top-level json OR inside trackSource
        commentsCount: (json['commentsCount'] as int?)
            ?? (trackSource['commentsCount'] as int?)
            ?? 0,
        repostsCount: trackSource['repostsCount'] as int? ?? 0,
        playsCount: trackSource['playsCount'] as int? ?? 0,
      );
    }

    // ── UserState: liked/reposted from feed response ──────────────────────────
    final TrackUserStateModel userState;
    if (trackSource['userState'] != null) {
      userState = TrackUserStateModel.fromJson(
          trackSource['userState'] as Map<String, dynamic>);
    } else {
      userState = TrackUserStateModel(
        liked: trackSource['liked'] as bool? ?? false,
        reposted: trackSource['reposted'] as bool? ?? false,
        inLibrary: trackSource['inLibrary'] as bool? ?? false,
      );
    }

    final track = FeedTrackModel(
      trackId: trackSource['id'] as String? ?? '',
      title: trackSource['title'] as String? ?? '',
      slug: trackSource['slug'] as String? ?? '',
      durationMs: trackSource['durationMs'] as int? ?? 0,
      status: trackSource['status'] as String? ?? 'FINISHED',
      visibility: trackSource['visibility'] as String? ?? 'PUBLIC',
      coverArtUrl: trackSource['coverArtUrl'] as String? ??
          trackSource['cover_art_url'] as String?,
      genre: trackSource['genre'] as String? ?? '',
      waveformData: waveform,
      audioUrl: trackSource['audioUrl'] as String? ??
          trackSource['audio_url'] as String?,
      artist: trackArtist,
      stats: stats,
      userState: userState,
    );

    return FeedItemModel(
      activityId: json['activityId'] as String? ??
          json['feed_id'] as String? ??
          trackSource['id'] as String? ??
          '',
      action: action,
      timeAgo: activityAt != null ? _timeAgo(activityAt) : '',
      createdAt: activityAt,
      actor: actor,
      track: track,
    );
  }

  static String _timeAgo(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
      if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
      return '${(diff.inDays / 365).floor()}y ago';
    } catch (_) {
      return '';
    }
  }
}

// ─── FeedPage Model ──────────────────────────────────────────────────────────

class FeedPageModel extends FeedPage {
  const FeedPageModel({
    required super.items,
    required super.page,
    required super.hasMore,
    required super.totalItems,
    required super.totalPages,
  });

  factory FeedPageModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['data'] as List<dynamic>?
        ?? json['items'] as List<dynamic>?
        ?? [];

    final items = rawItems
        .map((e) => FeedItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final pagination = json['pagination'] as Map<String, dynamic>?
        ?? json['meta'] as Map<String, dynamic>?
        ?? {};

    return FeedPageModel(
      items: items,
      page: pagination['page'] as int? ?? 1,
      hasMore: pagination['hasNextPage'] as bool? ?? false,
      totalItems: pagination['total'] as int? ?? items.length,
      totalPages: pagination['totalPages'] as int?
          ?? pagination['total_pages'] as int?
          ?? 1,
    );
  }
}

// ─── Search Models ────────────────────────────────────────────────────────────

class SearchUserResultModel extends SearchUserResult {
  const SearchUserResultModel({
    required super.id,
    required super.displayName,
    super.handle,
    super.avatarUrl,
  });

  factory SearchUserResultModel.fromJson(Map<String, dynamic> json) {
    return SearchUserResultModel(
      id: json['id'] as String? ?? '',
      displayName: json['display_name'] as String? ??
          json['displayName'] as String? ??
          '',
      handle: json['handle'] as String?,
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
    );
  }
}

class SearchTrackResultModel extends SearchTrackResult {
  const SearchTrackResultModel({
    required super.id,
    required super.title,
    super.genre,
    super.coverArtUrl,
    super.artistName,
  });

  factory SearchTrackResultModel.fromJson(Map<String, dynamic> json) {
    final artist = json['artist'] as Map<String, dynamic>?;
    return SearchTrackResultModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      genre: json['genre'] as String?,
      coverArtUrl:
          json['coverArtUrl'] as String? ?? json['cover_art_url'] as String?,
      artistName: artist?['displayName'] as String? ??
          artist?['display_name'] as String?,
    );
  }
}

class SearchPlaylistResultModel extends SearchPlaylistResult {
  const SearchPlaylistResultModel({
    required super.id,
    required super.title,
    super.coverArtUrl,
  });

  factory SearchPlaylistResultModel.fromJson(Map<String, dynamic> json) {
    return SearchPlaylistResultModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      coverArtUrl:
          json['coverArtUrl'] as String? ?? json['cover_art_url'] as String?,
    );
  }
}

class SearchResultsModel extends SearchResults {
  const SearchResultsModel({
    required super.users,
    required super.tracks,
    required super.playlists,
    required super.currentPage,
    required super.totalResults,
    required super.totalPages,
  });

  factory SearchResultsModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final meta = json['meta'] as Map<String, dynamic>? ?? {};

    return SearchResultsModel(
      users: (data['users'] as List<dynamic>? ?? [])
          .map((e) =>
              SearchUserResultModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      tracks: (data['tracks'] as List<dynamic>? ?? [])
          .map((e) =>
              SearchTrackResultModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      playlists: (data['playlists'] as List<dynamic>? ?? [])
          .map((e) =>
              SearchPlaylistResultModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: meta['current_page'] as int? ?? 1,
      totalResults: meta['total_results'] as int? ?? 0,
      totalPages: meta['total_pages'] as int? ?? 1,
    );
  }
}

// ─── Trending Model ───────────────────────────────────────────────────────────

class TrendingTrackModel extends TrendingTrack {
  const TrendingTrackModel({
    required super.id,
    required super.title,
    super.genre,
    super.coverArtUrl,
    super.artistName,
    super.artistHandle,
    required super.playsCount,
    required super.likesCount,
    required super.repostsCount,
  });

  factory TrendingTrackModel.fromJson(Map<String, dynamic> json) {
    final artist = json['artist'] as Map<String, dynamic>?;
    final stats = json['stats'] as Map<String, dynamic>?;

    return TrendingTrackModel(
      id: json['id'] as String? ?? json['trackId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      genre: json['genre'] as String?,
      coverArtUrl:
          json['coverArtUrl'] as String? ?? json['cover_art_url'] as String?,
      artistName: artist?['displayName'] as String? ??
          artist?['display_name'] as String?,
      artistHandle: artist?['handle'] as String?,
      playsCount:
          stats?['playsCount'] as int? ?? json['playsCount'] as int? ?? 0,
      likesCount:
          stats?['likesCount'] as int? ?? json['likesCount'] as int? ?? 0,
      repostsCount: stats?['repostsCount'] as int? ??
          json['repostsCount'] as int? ??
          0,
    );
  }
}

// ─── Resolve Model ────────────────────────────────────────────────────────────

class ResolveResultModel extends ResolveResult {
  const ResolveResultModel({
    required super.type,
    required super.resourceId,
    super.ownerId,
  });

  factory ResolveResultModel.fromJson(Map<String, dynamic> json) {
    return ResolveResultModel(
      type: json['type'] as String? ?? '',
      resourceId: json['resource_id'] as String? ?? '',
      ownerId: json['owner_id'] as String?,
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

String formatCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}