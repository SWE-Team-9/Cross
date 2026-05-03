import '../../../../core/network/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../dto/resolved_resource_model.dart';
import '../dto/trending_track_model.dart';

abstract class DiscoveryRemoteDataSource {
  Future<ResolvedResourceModel> resolveUrl(String url);

  Future<List<TrendingTrackModel>> getTrending({
    int limit = 20,
    int windowDays = 7,
  });

  Future<List<TrendingTrackModel>> getGenreTrendingTracks({
    required String genreSlug,
    int limit = 5,
  });
}

class DiscoveryRemoteDataSourceImpl implements DiscoveryRemoteDataSource {
  const DiscoveryRemoteDataSourceImpl(this._client);

  final DioClient _client;

  @override
  Future<ResolvedResourceModel> resolveUrl(String url) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.resolve,
      queryParameters: {'url': url.trim()},
    );

    return ResolvedResourceModel.fromJson(
      response.data ?? <String, dynamic>{},
    );
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
  Future<List<TrendingTrackModel>> getGenreTrendingTracks({
    required String genreSlug,
    int limit = 5,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.discoveryTrendingGenreTracksPath(genreSlug),
      queryParameters: {'limit': limit},
    );

    final body = response.data ?? <String, dynamic>{};
    final tracks = _extractList(body, const ['tracks', 'items', 'data']);

    return tracks.map(TrendingTrackModel.fromJson).toList(growable: false);
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
