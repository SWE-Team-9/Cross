// playback/data/datasources/track_detail_remote_data_source.dart

// Third-party
import 'package:injectable/injectable.dart';

// Project
import '../../../../core/errors/failure.dart';
import '../../../../core/network/dio_client.dart';
import '../dto/track_detail_dto.dart';
import '../dto/track_source_dto.dart';

/// Remote data source for track detail and stream URL.
///
/// Uses [DioClient] — all interceptors (auth, refresh, logging) run
/// automatically. Never use raw Dio directly.
@lazySingleton
class TrackDetailRemoteDataSource {
  const TrackDetailRemoteDataSource(this._client);

  final DioClient _client;

  /// Fetches full track detail for a public track.
  /// GET /api/v1/tracks/{trackId}
  ///
  /// Throws [Failure] (via ErrorMapper) on any network or API error.
  Future<TrackDetailDto> fetchByTrackId(String trackId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/api/v1/tracks/$trackId',
    );
    return TrackDetailDto.fromJson(response.data ?? {});
  }

  /// Fetches full track detail for a private track via secret token.
  /// GET /api/v1/tracks/secret/{secretToken}
  ///
  /// Throws [Failure] (via ErrorMapper) on any network or API error.
  /// 404 means the token is invalid or the track switched visibility.
  Future<TrackDetailDto> fetchBySecretToken(String secretToken) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/api/v1/tracks/secret/$secretToken',
    );
    return TrackDetailDto.fromJson(response.data ?? {});
  }

  /// Fetches the CDN stream URL for a track.
  /// GET /api/v1/player/tracks/{trackId}/source
  ///
  /// Throws [Failure] (via ErrorMapper) on any network or API error.
  Future<TrackSourceDto> fetchStreamSource(String trackId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/api/v1/player/tracks/$trackId/source',
    );
    return TrackSourceDto.fromJson(response.data ?? {});
  }
}