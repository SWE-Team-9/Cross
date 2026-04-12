import 'package:injectable/injectable.dart';

import '../../../../core/network/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../dto/track_status_dto.dart';

abstract class TrackStatusRemoteDataSource {
  Future<TrackStatusDto> getTrackStatus(String trackId);
}

@LazySingleton(as: TrackStatusRemoteDataSource)
class TrackStatusRemoteDataSourceImpl implements TrackStatusRemoteDataSource {
  const TrackStatusRemoteDataSourceImpl(this._dioClient);

  final DioClient _dioClient;

  @override
  Future<TrackStatusDto> getTrackStatus(String trackId) async {
    final response = await _dioClient.get(
      ApiConstants.trackStatusPath(trackId),
    );

    return TrackStatusDto.fromJson(response.data as Map<String, dynamic>);
  }
}
