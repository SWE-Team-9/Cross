import '../../../../core/network/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../dto/track_detail_dto.dart';
import '../dto/track_source_dto.dart';

class TrackDetailRemoteDataSource {
  const TrackDetailRemoteDataSource(this._client);

  final DioClient _client;

  Future<TrackDetailDto> fetchByTrackId(String trackId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/api/v1/tracks/$trackId',
    );
    return TrackDetailDto.fromJson(response.data ?? {});
  }

  Future<TrackDetailDto> fetchBySecretToken(String secretToken) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/api/v1/tracks/secret/$secretToken',
    );
    return TrackDetailDto.fromJson(response.data ?? {});
  }

  // ✅ يعمل resolve بالـ handle/slug الأول، بعدين يجيب الـ track بالـ id
  Future<TrackDetailDto> fetchBySlug(String handle, String slug) async {
    // Step 1 — بنبني الـ URL من الـ baseUrl الموجود في الـ client
    final baseUrl = _client.dio.options.baseUrl.replaceAll(RegExp(r'/$'), '');
    final trackUrl = '$baseUrl/$handle/$slug';

    final resolveResponse = await _client.get<Map<String, dynamic>>(
      ApiConstants.resolve,
      queryParameters: {'url': trackUrl},
    );

    final data = resolveResponse.data ?? {};
    final bool matched = data['matched'] as bool? ?? false;

    if (!matched) {
      throw Exception('Track not found');
    }

    final String resourceType = data['resourceType'] as String? ?? '';
    if (resourceType != 'TRACK') {
      throw Exception('URL does not resolve to a track');
    }

    final String trackId = data['id'] as String? ?? '';
    if (trackId.isEmpty) {
      throw Exception('Track ID missing in resolve response');
    }

    // Step 2 — نجيب الـ track بالـ id
    return fetchByTrackId(trackId);
  }

  Future<TrackSourceDto> fetchStreamSource(String trackId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/api/v1/player/tracks/$trackId/source',
    );
    return TrackSourceDto.fromJson(response.data ?? {});
  }
}
