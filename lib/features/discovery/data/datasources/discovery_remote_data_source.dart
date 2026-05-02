// lib/features/discovery/data/datasources/discovery_remote_data_source.dart

import '../../../../core/network/api_constants.dart';
import '/core/network/dio_client.dart';
import '../dto/resolved_resource_model.dart';
import '../dto/trending_track_model.dart';

abstract class DiscoveryRemoteDataSource {
  Future<ResolvedResourceModel> resolveUrl(String url);
  Future<List<TrendingTrackModel>> getTrending();
}

class DiscoveryRemoteDataSourceImpl implements DiscoveryRemoteDataSource {
  const DiscoveryRemoteDataSourceImpl(this._client);

  final DioClient _client;

  @override
  Future<ResolvedResourceModel> resolveUrl(String url) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.resolve,
      queryParameters: {'url': url},
    );
    return ResolvedResourceModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  // GET /api/v1/discovery/trending
  // الـ response: { windowDays: 7, items: [...] }
  @override
  Future<List<TrendingTrackModel>> getTrending() async {
    final res = await _client.get<dynamic>(ApiConstants.trending);

    List<dynamic> list;
    if (res.data is List) {
      list = res.data as List;
    } else if (res.data is Map) {
      final data = res.data as Map<String, dynamic>;
      if (data['items'] is List) {
        list = data['items'] as List; // ✅ { windowDays, items: [...] }
      } else if (data['data'] is List) {
        list = data['data'] as List; // fallback
      } else {
        list = [];
      }
    } else {
      list = [];
    }

    return list
        .map((e) => TrendingTrackModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
