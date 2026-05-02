// coverage:ignore-file
// ─────────────────────────────────────────────────────────────────────────────
//  feed_remote_data_source.dart  —  Real HTTP Calls via DioClient
//
//  Endpoints:
//    Feed       → GET  /api/v1/feed?page=&limit=&includeReposts=
//    Search     → GET  /api/v1/discovery/search?q=&page=
//    Trending   → GET  /api/v1/discovery/trending
//    Resolve    → GET  /api/v1/discovery/resolve?url=
//    Player     → GET  /api/v1/player/tracks/{trackId}/source
//                 POST /api/v1/player/tracks/{trackId}/play
//    Like       → POST   /api/v1/interactions/tracks/{trackId}/like
//                 DELETE /api/v1/interactions/tracks/{trackId}/like
//    Repost     → POST   /api/v1/interactions/tracks/{trackId}/repost
//                 DELETE /api/v1/interactions/tracks/{trackId}/repost
// ─────────────────────────────────────────────────────────────────────────────

import '../../../../core/network/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../dto/feed_item_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DTOs — Activity Feed
// ─────────────────────────────────────────────────────────────────────────────

/// Represents the actor (user) who performed the activity (post or repost).
class FeedActorModel {
  final String id;
  final String displayName;
  final String handle;
  final String? avatarUrl;

  const FeedActorModel({
    required this.id,
    required this.displayName,
    required this.handle,
    this.avatarUrl,
  });

  factory FeedActorModel.fromJson(Map<String, dynamic> json) {
    // Supports both flat and nested { profile: {...} } shapes.
    final profile = json['profile'] as Map<String, dynamic>? ?? json;
    return FeedActorModel(
      id: (json['id'] as String?) ?? '',
      displayName: (profile['displayName'] as String?) ?? '',
      handle: (profile['handle'] as String?) ?? '',
      avatarUrl: profile['avatarUrl'] as String?,
    );
  }
}

/// Full track card data embedded in each feed activity item.
class FeedTrackModel {
  final String id;
  final String title;
  final String slug;
  final String? coverArtUrl;
  final int? durationMs;
  final List<double>? waveformData;
  final int likesCount;
  final int commentsCount;
  final bool liked;
  final int repostsCount;
  final bool reposted;
  final String artistId;
  final String artistName;
  final String artistHandle;
  final String? artistAvatarUrl;
  final String status;
  final String visibility;

  const FeedTrackModel({
    required this.id,
    required this.title,
    required this.slug,
    this.coverArtUrl,
    this.durationMs,
    this.waveformData,
    required this.likesCount,
    required this.commentsCount,
    required this.liked,
    required this.repostsCount,
    required this.reposted,
    required this.artistId,
    required this.artistName,
    required this.artistHandle,
    this.artistAvatarUrl,
    required this.status,
    required this.visibility,
  });

  factory FeedTrackModel.fromJson(Map<String, dynamic> json) {
    // Artist info can live flat on the track or nested under uploader/profile.
    final uploader = json['uploader'] as Map<String, dynamic>?;
    final profile = uploader?['profile'] as Map<String, dynamic>?;

    final artistId =
        (json['artistId'] as String?) ?? (json['uploaderId'] as String?) ?? '';
    final artistName = (json['artistName'] as String?) ??
        (profile?['displayName'] as String?) ??
        '';
    final artistHandle = (json['artistHandle'] as String?) ??
        (profile?['handle'] as String?) ??
        '';
    final artistAvatarUrl =
        (json['artistAvatarUrl'] as String?) ?? (profile?['avatarUrl'] as String?);

    // waveformData may arrive as List<num> or be absent.
    List<double>? waveform;
    final raw = json['waveformData'];
    if (raw is List) {
      waveform = raw.map((e) => (e as num).toDouble()).toList();
    }

    return FeedTrackModel(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      slug: (json['slug'] as String?) ?? '',
      coverArtUrl: json['coverArtUrl'] as String?,
      durationMs: json['durationMs'] as int?,
      waveformData: waveform,
      likesCount: (json['likesCount'] as int?) ?? 0,
      liked: (json['liked'] as bool?) ?? false,
      repostsCount: (json['repostsCount'] as int?) ?? 0,
      commentsCount: (json['commentsCount'] as int?) ?? 0,
      reposted: (json['reposted'] as bool?) ?? false,
      artistId: artistId,
      artistName: artistName,
      artistHandle: artistHandle,
      artistAvatarUrl: artistAvatarUrl,
      status: (json['status'] as String?) ?? 'published',
      visibility: (json['visibility'] as String?) ?? 'public',
    );
  }
}

/// A single activity item in the feed (a POST or a REPOST).
class FeedActivityItemModel {
  /// Unique activity id (distinct from the track id).
  final String id;

  /// 'POST' or 'REPOST'
  final String actionType;

  /// ISO-8601 timestamp of when the activity occurred.
  final String activityAt;

  /// The user who performed the action.
  final FeedActorModel actor;

  /// The full track card.
  final FeedTrackModel track;

  const FeedActivityItemModel({
    required this.id,
    required this.actionType,
    required this.activityAt,
    required this.actor,
    required this.track,
  });

  factory FeedActivityItemModel.fromJson(Map<String, dynamic> json) {
    // ── Resolve track payload ──────────────────────────────────────────────
    // The server may embed track fields under a 'track' key OR at the top level
    // (current response shape). We support both.
    final trackJson = (json['track'] as Map<String, dynamic>?) ?? json;

    // ── Resolve actor payload ──────────────────────────────────────────────
    // The server may embed actor fields under an 'actor' key OR derive them
    // from the track's uploader (current response shape).
    final Map<String, dynamic> actorJson;
    if (json['actor'] != null) {
      actorJson = json['actor'] as Map<String, dynamic>;
    } else {
      // Derive actor from uploader embedded in track/top-level json.
      final uploader =
          (trackJson['uploader'] as Map<String, dynamic>?) ?? const {};
      final profile =
          (uploader['profile'] as Map<String, dynamic>?) ?? const {};
      actorJson = {
        'id': trackJson['uploaderId'] ?? '',
        'profile': profile,
      };
    }

    // ── Resolve activity metadata ──────────────────────────────────────────
    final actionType =
        (json['actionType'] as String?) ?? 'POST'; // default → POST
    final activityAt = (json['activityAt'] as String?) ??
        (trackJson['publishedAt'] as String?) ??
        (trackJson['createdAt'] as String?) ??
        '';

    // ── Unique activity id ─────────────────────────────────────────────────
    // Prefer a dedicated activity id; fall back to track id.
    final id =
        (json['activityId'] as String?) ?? (trackJson['id'] as String?) ?? '';

    return FeedActivityItemModel(
      id: id,
      actionType: actionType,
      activityAt: activityAt,
      actor: FeedActorModel.fromJson(actorJson),
      track: FeedTrackModel.fromJson(trackJson),
    );
  }
}

/// Pagination metadata returned by the feed endpoint.
class FeedPaginationModel {
  final int page;
  final int limit;
  final int offset;
  final int total;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const FeedPaginationModel({
    required this.page,
    required this.limit,
    required this.offset,
    required this.total,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory FeedPaginationModel.fromJson(Map<String, dynamic> json) {
    return FeedPaginationModel(
      page: (json['page'] as int?) ?? 1,
      limit: (json['limit'] as int?) ?? 20,
      offset: (json['offset'] as int?) ?? 0,
      total: (json['total'] as int?) ?? 0,
      totalPages: (json['totalPages'] as int?) ??
          (json['total_pages'] as int?) ??
          1,
      hasNextPage: (json['hasNextPage'] as bool?) ?? false,
      hasPreviousPage: (json['hasPreviousPage'] as bool?) ?? false,
    );
  }
}

/// Full paginated feed response.
///
/// Replaces the old [FeedPageModel] with the enriched activity shape.
class ActivityFeedPageModel {
  final List<FeedActivityItemModel> items;
  final FeedPaginationModel pagination;

  const ActivityFeedPageModel({
    required this.items,
    required this.pagination,
  });

  factory ActivityFeedPageModel.fromJson(Map<String, dynamic> json) {
    print('🔴 raw json keys: ${json.keys.toList()}');
    final rawItems = (json['data'] as List<dynamic>?)
    ?? (json['items'] as List<dynamic>?)
    ?? [];
    print('🔴 rawItems count: ${rawItems.length}');

    final items = rawItems
        .map((e) =>
            FeedActivityItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final paginationJson =
        (json['pagination'] as Map<String, dynamic>?) ??
            (json['meta'] as Map<String, dynamic>?) ??
            const {};

    return ActivityFeedPageModel(
      items: items,
      pagination: FeedPaginationModel.fromJson(paginationJson),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Abstract contract
// ─────────────────────────────────────────────────────────────────────────────

abstract class FeedRemoteDataSource {
  /// GET /api/v1/feed?page=&limit=&includeReposts=
  Future<ActivityFeedPageModel> getFeed({
    required int page,
    int limit = 20,
  });

  Future<Map<String, dynamic>> toggleLike(
      {required String trackId, required bool currentlyLiked});
  Future<Map<String, dynamic>> toggleRepost(
      {required String trackId, required bool currentlyReposted});
  Future<Map<String, dynamic>> getTrackSource(String trackId);
  Future<void> recordPlay(String trackId);
  Future<SearchResultsModel> search({required String query, int page = 1});
  Future<List<TrendingTrackModel>> getTrending();
  Future<ResolveResultModel> resolve(String permalink);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Implementation
// ─────────────────────────────────────────────────────────────────────────────

class FeedRemoteDataSourceImpl implements FeedRemoteDataSource {
  final DioClient _client;

  FeedRemoteDataSourceImpl({required DioClient client}) : _client = client;

  // ─── Activity Feed ───────────────────────────────────────────────────────
  // GET /api/v1/feed?page=1&limit=20&includeReposts=true
  //
  // Response shape:
  // {
  //   "data": [ { ...activityItem } ],
  //   "pagination": { page, limit, offset, total, totalPages,
  //                   hasNextPage, hasPreviousPage }
  // }

  @override
  Future<ActivityFeedPageModel> getFeed({
    required int page,
    int limit = 20,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiConstants.activityFeed,
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );
    return ActivityFeedPageModel.fromJson(res.data!);
  }

  // ─── Like ────────────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> toggleLike({
    required String trackId,
    required bool currentlyLiked,
  }) async {
    if (currentlyLiked) {
      final res = await _client.delete<Map<String, dynamic>>(
        ApiConstants.likeTrackPath(trackId),
      );
      return res.data ?? {};
    } else {
      final res = await _client.post<Map<String, dynamic>>(
        ApiConstants.likeTrackPath(trackId),
      );
      return res.data ?? {};
    }
  }

  // ─── Repost ──────────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> toggleRepost({
    required String trackId,
    required bool currentlyReposted,
  }) async {
    if (currentlyReposted) {
      final res = await _client.delete<Map<String, dynamic>>(
        ApiConstants.repostTrackPath(trackId),
      );
      return res.data ?? {};
    } else {
      final res = await _client.post<Map<String, dynamic>>(
        ApiConstants.repostTrackPath(trackId),
      );
      return res.data ?? {};
    }
  }

  // ─── Playback ────────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> getTrackSource(String trackId) async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiConstants.playerTrackSourcePath(trackId),
    );
    return res.data!;
  }

  @override
  Future<void> recordPlay(String trackId) async {
    await _client.post<void>(ApiConstants.playerTrackPlayPath(trackId));
  }

  // ─── Search ──────────────────────────────────────────────────────────────
  // GET /api/v1/discovery/search?q=&page=

  @override
  Future<SearchResultsModel> search({
    required String query,
    int page = 1,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiConstants.globalSearch,
      queryParameters: {'q': query.trim(), 'page': page},
    );
    return SearchResultsModel.fromJson(res.data!);
  }

  // ─── Trending ────────────────────────────────────────────────────────────
  // GET /api/v1/discovery/trending

  @override
  Future<List<TrendingTrackModel>> getTrending() async {
    final res = await _client.get<dynamic>(ApiConstants.trending);

    List<dynamic> list;
    if (res.data is List) {
      list = res.data as List;
    } else if (res.data is Map && res.data['data'] is List) {
      list = res.data['data'] as List;
    } else {
      list = [];
    }

    return list
        .map((e) => TrendingTrackModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── Resolve ─────────────────────────────────────────────────────────────
  // GET /api/v1/discovery/resolve?url=

  @override
  Future<ResolveResultModel> resolve(String permalink) async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiConstants.resolve,
      queryParameters: {'url': permalink},
    );
    return ResolveResultModel.fromJson(res.data!);
  }
}