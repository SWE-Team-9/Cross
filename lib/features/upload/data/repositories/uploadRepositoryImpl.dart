import 'package:dio/dio.dart';

import '../../../../core/network/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/PickedAudioFile.dart';
import '../../domain/repositories/uploadRepository.dart';
import '../datasources/audioFilePickerDataSource.dart';

class UploadRepositoryImpl implements UploadRepository {
  const UploadRepositoryImpl(
    this._audioFilePickerDataSource, {
    DioClient? dioClient,
  }) : _dioClient = dioClient;

  final AudioFilePickerDataSource _audioFilePickerDataSource;
  final DioClient? _dioClient;

  @override
  Future<PickedAudioFile?> pickAudioFile() async {
    final result = await _audioFilePickerDataSource.pickAudioFile();
    return result?.toEntity();
  }

  @override
  Future<UploadTrackResult> uploadTrack({
    required PickedAudioFile file,
    required String title,
    String? genre,
  }) async {
    final DioClient? dioClient = _dioClient;
    if (dioClient == null) {
      throw Exception(
        'Upload API client is not configured. Inject DioClient into UploadRepositoryImpl.',
      );
    }

    final String? filePath = file.path;
    if (filePath == null || filePath.trim().isEmpty) {
      throw Exception('Selected audio file path is unavailable on this platform.');
    }

    final formData = FormData.fromMap({
      'title': title.trim(),
      if (genre != null && genre.trim().isNotEmpty) 'genre': genre.trim(),
      'audioFile': await MultipartFile.fromFile(
        filePath,
        filename: file.name,
      ),
    });

    final response = await dioClient.post(
      ApiConstants.tracks,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final payload = _extractPayloadMap(response);

    final String trackId = (payload['trackId'] ??
            payload['track_id'] ??
            payload['id'] ??
            '')
        .toString();

    if (trackId.isEmpty) {
      throw const FormatException('Upload response did not include a trackId.');
    }

    final String status = (payload['status'] ?? 'PROCESSING').toString();

    return UploadTrackResult(
      trackId: trackId,
      status: status,
    );
  }

  @override
  Future<String> getTrackStatus({
    required String trackId,
  }) async {
    final DioClient? dioClient = _dioClient;
    if (dioClient == null) {
      throw Exception(
        'Upload API client is not configured. Inject DioClient into UploadRepositoryImpl.',
      );
    }

    final response = await dioClient.get(
      ApiConstants.trackStatusPath(trackId),
    );

    final payload = _extractPayloadMap(response);
    final String status = (payload['status'] ?? '').toString();

    if (status.isEmpty) {
      throw const FormatException('Track status response did not include status.');
    }

    return status;
  }
}

Map<String, dynamic> _extractPayloadMap(dynamic response) {
  final dynamic data = response is Map<String, dynamic> ? response : response.data;

  if (data is Map<String, dynamic>) {
    if (data['track'] is Map<String, dynamic>) {
      return Map<String, dynamic>.from(data['track'] as Map<String, dynamic>);
    }

    if (data['data'] is Map<String, dynamic>) {
      return Map<String, dynamic>.from(data['data'] as Map<String, dynamic>);
    }

    return Map<String, dynamic>.from(data);
  }

  throw const FormatException('Unexpected upload response format.');
}