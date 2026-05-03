// coverage:ignore-file

import '../../../../core/network/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../dto/feed_item_model.dart'
    show ResolveResultModel, SearchResultsModel, TrendingTrackModel;

// ─────────────────────────────────────────────────────────────────────────────
// Activity Feed DTOs
// ─────────────────────────────────────────────────────────────────────────────

class FeedActorModel {
  final String id;
  final String displayName;
  final String handle;
  final String? avatarUrl;
  final bool verified;

  const FeedActorModel({
    required this.id,
    required this.displayName,
    required this.handle,
    this.avatarUrl,
    required this.verified,
  });

  factory FeedActorModel.fromJson(Map<String, dynamic> json) {
    final profile = _map(json['profile']);

    return FeedActorModel(
      id: _s(json['id'] ?? json['userId'] ?? json['uploaderId']),
      displayName: _s(
        json['displayName'] ??
            json['display_name'] ??
            profile['displayName'] ??
            profile['display_name'] ??
            profile['handle'],
      ),
      handle: _s(json['handle'] ?? profile['handle']),
      avatarUrl: _nullableString(
        json['avatarUrl'] ?? json['avatar_url'] ?? profile['avatarUrl'],
      ),
      verified:
          json['verified'] as bool? ?? profile['verified'] as bool? ?? false,
    );
  }
}

class FeedTrackModel {
  final String id;
  final String title;
  final String slug;
  final String? coverArtUrl;
  final int? durationMs;
  final List<double>? waveformData;
  final int likesCount;
  final int commentsCount;
  final int repostsCount;
  final int playsCount;
  final bool liked;
  final bool reposted;
  final String artistId;
  final String artistName;
  final String artistHandle;
  final String? artistAvatarUrl;
  final String genre;
  final String status;
  final String visibility;
  final String? audioUrl;

  const FeedTrackModel({
    required this.id,
    required this.title,
    required this.slug,
    this.coverArtUrl,
    this.durationMs,
    this.waveformData,
    required this.likesCount,
    required this.commentsCount,
    required this.repostsCount,
    required this.playsCount,
    required this.liked,
    required this.reposted,
    required this.artistId,
    required this.artistName,
    required this.artistHandle,
    this.artistAvatarUrl,
    required this.genre,
    required this.status,
    required this.visibility,
    this.audioUrl,
  });

  factory FeedTrackModel.fromJson(Map<String, dynamic> json) {
    final uploader = _map(json['uploader']);
    final uploaderProfile = _map(uploader['profile']);
    final artist = _map(json['artist']);
    final genreMap = _map(json['genre']);
    final stats = _map(json['stats']);
    final userState = _map(json['userState']);

    return FeedTrackModel(
      id: _s(json['id'] ?? json['trackId']),
      title: _s(json['title']),
      slug: _s(json['slug']),
      coverArtUrl: _nullableString(
        json['coverArtUrl'] ?? json['cover_art_url'] ?? json['artworkUrl'],
      ),
      durationMs: _nullableInt(json['durationMs'] ?? json['duration_ms']),
      waveformData: _waveform(json['waveformData']),
      likesCount: _int(json['likesCount'] ?? stats['likesCount']),
      commentsCount: _int(json['commentsCount'] ?? stats['commentsCount']),
      repostsCount: _int(json['repostsCount'] ?? stats['repostsCount']),
      playsCount: _int(json['playsCount'] ?? stats['playsCount']),
      liked: json['liked'] as bool? ?? userState['liked'] as bool? ?? false,
      reposted:
          json['reposted'] as bool? ?? userState['reposted'] as bool? ?? false,
      artistId: _s(
        json['artistId'] ??
            json['uploaderId'] ??
            artist['id'] ??
            uploader['userId'] ??
            uploader['id'],
      ),
      artistName: _s(
        json['artistName'] ??
            artist['displayName'] ??
            artist['handle'] ??
            uploaderProfile['displayName'] ??
            uploaderProfile['handle'],
      ),
      artistHandle: _s(
        json['artistHandle'] ?? artist['handle'] ?? uploaderProfile['handle'],
      ),
      artistAvatarUrl: _nullableString(
        json['artistAvatarUrl'] ??
            artist['avatarUrl'] ??
            uploaderProfile['avatarUrl'],
      ),
      genre: _s(genreMap['slug'] ?? genreMap['name'] ?? json['genre']),
      status: _s(json['status'], fallback: 'PUBLISHED'),
      visibility: _s(json['visibility'], fallback: 'PUBLIC'),
      audioUrl: _nullableString(
        json['audioUrl'] ?? json['audio_url'] ?? json['streamUrl'],
      ),
    );
  }
}

class FeedActivityItemModel {
  final String id;
  final String actionType;
  final String activityAt;
  final FeedActorModel actor;
  final FeedTrackModel track;

  const FeedActivityItemModel({
    required this.id,
    required this.actionType,
    required this.activityAt,
    required this.actor,
    required this.track,
  });

  factory FeedActivityItemModel.fromJson(Map<String, dynamic> json) {
    final trackJson =
        _map(json['track']).isNotEmpty ? _map(json['track']) : json;
    final explicitActor = _map(json['actor']);

    final actorJson = explicitActor.isNotEmpty
        ? explicitActor
        : <String, dynamic>{
            'id': trackJson['uploaderId'],
            'profile': _map(_map(trackJson['uploader'])['profile']),
          };

    final activityAt = _s(
      json['activityAt'] ??
          json['createdAt'] ??
          json['created_at'] ??
          trackJson['publishedAt'] ??
          trackJson['createdAt'],
    );

    return FeedActivityItemModel(
      id: _s(
        json['activityId'] ??
            json['feed_id'] ??
            json['id'] ??
            trackJson['id'] ??
            trackJson['trackId'],
      ),
      actionType: _s(
        json['actionType'] ?? json['action_type'] ?? json['action'],
        fallback: 'POST',
      ),
      activityAt: activityAt,
      actor: FeedActorModel.fromJson(actorJson),
      track: FeedTrackModel.fromJson(trackJson),
    );
  }
}

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
      page: _int(json['page'] ?? json['currentPage'] ?? json['current_page']),
      limit: _int(json['limit']),
      offset: _int(json['offset']),
      total: _int(json['total'] ?? json['totalItems'] ?? json['total_results']),
      totalPages: _int(json['totalPages'] ?? json['total_pages']),
      hasNextPage: json['hasNextPage'] as bool? ??
          json['has_next_page'] as bool? ??
          false,
      hasPreviousPage: json['hasPreviousPage'] as bool? ??
          json['has_previous_page'] as bool? ??
          false,
    );
  }
}

class ActivityFeedPageModel {
  final List<FeedActivityItemModel> items;
  final FeedPaginationModel pagination;

  const ActivityFeedPageModel({
    required this.items,
    required this.pagination,
  });

  factory ActivityFeedPageModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['data'] as List<dynamic>? ??
        json['items'] as List<dynamic>? ??
        const [];

    final paginationJson = _map(json['pagination']).isNotEmpty
        ? _map(json['pagination'])
        : _map(json['meta']);

    return ActivityFeedPageModel(
      items: rawItems
          .whereType<Map>()
          .map((item) => FeedActivityItemModel.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(growable: false),
      pagination: FeedPaginationModel.fromJson(paginationJson),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Remote contract
// ─────────────────────────────────────────────────────────────────────────────

abstract class FeedRemoteDataSource {
  Future<ActivityFeedPageModel> getFeed({
    required int page,
    int limit = 20,
    int? offset,
  });

  Future<Map<String, dynamic>> toggleLike({
    required String trackId,
    required bool currentlyLiked,
  });

  Future<Map<String, dynamic>> toggleRepost({
    required String trackId,
    required bool currentlyReposted,
  });

  Future<Map<String, dynamic>> getTrackSource(String trackId);

  Future<void> recordPlay(String trackId);

  Future<SearchResultsModel> search({
    required String query,
    String? type,
    int page = 1,
    int limit = 20,
  });

  Future<List<TrendingTrackModel>> getTrending({
    int limit = 20,
    int windowDays = 7,
  });

  Future<ResolveResultModel> resolve(String permalink);
}

// ─────────────────────────────────────────────────────────────────────────────
// Implementation
// ─────────────────────────────────────────────────────────────────────────────

class FeedRemoteDataSourceImpl implements FeedRemoteDataSource {
  final DioClient _client;

  FeedRemoteDataSourceImpl({required DioClient client}) : _client = client;

  @override
  Future<ActivityFeedPageModel> getFeed({
    required int page,
    int limit = 20,
    int? offset,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.activityFeed,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (offset != null) 'offset': offset,
      },
    );

    return ActivityFeedPageModel.fromJson(
      response.data ?? <String, dynamic>{},
    );
  }

  @override
  Future<Map<String, dynamic>> toggleLike({
    required String trackId,
    required bool currentlyLiked,
  }) async {
    final response = currentlyLiked
        ? await _client.delete<Map<String, dynamic>>(
            ApiConstants.likeTrackPath(trackId),
          )
        : await _client.post<Map<String, dynamic>>(
            ApiConstants.likeTrackPath(trackId),
          );

    return response.data ?? <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> toggleRepost({
    required String trackId,
    required bool currentlyReposted,
  }) async {
    final response = currentlyReposted
        ? await _client.delete<Map<String, dynamic>>(
            ApiConstants.repostTrackPath(trackId),
          )
        : await _client.post<Map<String, dynamic>>(
            ApiConstants.repostTrackPath(trackId),
          );

    return response.data ?? <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> getTrackSource(String trackId) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.playerTrackSourcePath(trackId),
    );

    return response.data ?? <String, dynamic>{};
  }

  @override
  Future<void> recordPlay(String trackId) async {
    await _client.post<void>(ApiConstants.playerTrackPlayPath(trackId));
  }

  @override
  Future<SearchResultsModel> search({
    required String query,
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.globalSearch,
      queryParameters: {
        'q': query.trim(),
        if (type != null && type.trim().isNotEmpty) 'type': type.trim(),
        'page': page,
        'limit': limit,
      },
    );

    return SearchResultsModel.fromJson(response.data ?? <String, dynamic>{});
  }

  @override
  Future<List<TrendingTrackModel>> getTrending({
    int limit = 20,
    int windowDays = 7,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.trending,
      queryParameters: {
        'limit': limit,
        'windowDays': windowDays,
      },
    );

    final body = response.data ?? <String, dynamic>{};
    final items = _extractList(body, const ['items', 'data', 'tracks']);

    return items.map(TrendingTrackModel.fromJson).toList(growable: false);
  }

  @override
  Future<ResolveResultModel> resolve(String permalink) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.resolve,
      queryParameters: {'url': permalink.trim()},
    );

    final body = response.data ?? <String, dynamic>{};

    if (body['matched'] == false) {
      return const ResolveResultModel(
        type: '',
        resourceId: '',
        ownerId: null,
      );
    }

    return ResolveResultModel(
      type: _s(body['resourceType'] ?? body['type']),
      resourceId: _s(body['id'] ?? body['resource_id'] ?? body['resourceId']),
      ownerId: _nullableString(
        body['owner_id'] ?? body['ownerId'] ?? body['handle'] ?? body['slug'],
      ),
    );
  }

  static List<Map<String, dynamic>> _extractList(
    Map<String, dynamic> body,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = body[key];
      if (value is List) {
        return value
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false);
      }
    }

    return const [];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

String _s(dynamic value, {String fallback = ''}) {
  final text = value?.toString() ?? '';
  return text.isEmpty ? fallback : text;
}

String? _nullableString(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int _int(dynamic value) {
  return _nullableInt(value) ?? 0;
}

int? _nullableInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

List<double>? _waveform(dynamic value) {
  if (value is! List) return null;

  return value
      .whereType<num>()
      .map((sample) => sample.toDouble())
      .toList(growable: false);
}
