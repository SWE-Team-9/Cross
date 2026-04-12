import '../../../../core/network/dio_client.dart';
import '../../domain/entities/managed_track.dart';
import '../../domain/entities/track_management_form.dart';
import '../../domain/entities/track_management_visibility.dart';
import '../dto/managed_track_dto.dart';

abstract class TrackManagementRemoteDataSource {
  Future<ManagedTrack> updateTrackMetadata({
    required String trackId,
    required TrackManagementForm form,
  });

  Future<ManagedTrack> updateTrackVisibility({
    required String trackId,
    required TrackManagementVisibility visibility,
  });

  Future<void> deleteTrack({
    required String trackId,
  });
}

class TrackManagementRemoteDataSourceImpl
    implements TrackManagementRemoteDataSource {
  const TrackManagementRemoteDataSourceImpl(this._dioClient);

  final DioClient _dioClient;

  @override
  Future<ManagedTrack> updateTrackMetadata({
    required String trackId,
    required TrackManagementForm form,
  }) async {
    final dynamic response = await _dioClient.put(
      '/tracks/$trackId',
      data: form.toMetadataRequestBody(),
    );

    final Map<String, dynamic> payload = _extractPayloadMap(response);

    return ManagedTrackDto.fromJson(payload).toEntity();
  }

  @override
  Future<ManagedTrack> updateTrackVisibility({
    required String trackId,
    required TrackManagementVisibility visibility,
  }) async {
    final dynamic response = await _dioClient.patch(
      '/tracks/$trackId/visibility',
      data: <String, dynamic>{
        'visibility': visibility.apiValue,
      },
    );

    final Map<String, dynamic> payload = _extractPayloadMap(response);

    return ManagedTrackDto.fromJson(payload).toEntity();
  }

  @override
  Future<void> deleteTrack({
    required String trackId,
  }) async {
    await _dioClient.delete('/tracks/$trackId');
  }
}

Map<String, dynamic> _extractPayloadMap(dynamic response) {
  final dynamic data =
      response is Map<String, dynamic> ? response : response.data;

  if (data is Map<String, dynamic>) {
    if (data['track'] is Map<String, dynamic>) {
      return Map<String, dynamic>.from(
        data['track'] as Map<String, dynamic>,
      );
    }

    if (data['data'] is Map<String, dynamic>) {
      return Map<String, dynamic>.from(
        data['data'] as Map<String, dynamic>,
      );
    }

    return Map<String, dynamic>.from(data);
  }

  throw const FormatException('Unexpected track response format.');
}
