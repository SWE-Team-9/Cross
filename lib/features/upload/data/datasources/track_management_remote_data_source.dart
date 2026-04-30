import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/managed_track.dart';
import '../../domain/entities/track_genre.dart';
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
    final body = form.toMetadataRequestBody();
    final apiGenre = trackGenreApiValue(form.normalizedGenreName);
    if (apiGenre == null) {
      body.remove('genre');
    } else {
      body['genre'] = apiGenre;
    }

    final dynamic response = await _dioClient.put(
      '/api/v1/tracks/$trackId', // تم إضافة /api/v1
      data: await _buildTrackMetadataFormData(
        body: body,
        coverArtPath: form.coverArtPath,
      ),
      options: Options(contentType: 'multipart/form-data'),
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
      '/api/v1/tracks/$trackId/visibility', // تم إضافة /api/v1
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
    await _dioClient.delete('/api/v1/tracks/$trackId'); // تم إضافة /api/v1
  }
}

Future<FormData> _buildTrackMetadataFormData({
  required Map<String, dynamic> body,
  required String? coverArtPath,
}) async {
  final formData = FormData();

  for (final entry in body.entries) {
    final value = entry.value;
    if (value == null) continue;

    if (value is Iterable) {
      for (final item in value) {
        formData.fields.add(MapEntry(entry.key, item.toString()));
      }
      continue;
    }

    formData.fields.add(MapEntry(entry.key, value.toString()));
  }

  if (coverArtPath != null && coverArtPath.trim().isNotEmpty) {
    formData.files.add(
      MapEntry(
        'coverArt',
        await MultipartFile.fromFile(coverArtPath),
      ),
    );
  }

  return formData;
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
