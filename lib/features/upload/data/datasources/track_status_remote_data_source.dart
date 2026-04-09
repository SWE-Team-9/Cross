import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../dto/track_status_dto.dart';

abstract class TrackStatusRemoteDataSource {
  Future<TrackStatusDto> getTrackStatus(String trackId);
}

@LazySingleton(as: TrackStatusRemoteDataSource)
class TrackStatusRemoteDataSourceImpl implements TrackStatusRemoteDataSource {
  const TrackStatusRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<TrackStatusDto> getTrackStatus(String trackId) async {
    final response = await _dio.get('/api/v1/tracks/$trackId/status');
    return TrackStatusDto.fromJson(response.data as Map<String, dynamic>);
  }
}
