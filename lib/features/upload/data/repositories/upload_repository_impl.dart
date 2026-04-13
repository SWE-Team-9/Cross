import 'package:dio/dio.dart';

import '../../../../core/network/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/picked_audio_file.dart';
import '../../domain/repositories/upload_repository.dart';
import '../datasources/audio_file_picker_data_source.dart';

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
    String? description,
    List<String> tags = const <String>[],
    UploadProgressCallback? onProgress,
  }) async {
    final DioClient? dioClient = _dioClient;
    if (dioClient == null) {
      throw Exception(
        'Upload API client is not configured. Inject DioClient into UploadRepositoryImpl.',
      );
    }

    final String? filePath = file.path;
    if (filePath == null || filePath.trim().isEmpty) {
      throw Exception(
        'Selected audio file path is unavailable on this platform.',
      );
    }

    final String normalizedTitle = title.trim();
    final String? normalizedGenre = _normalizeOptional(genre);
    final String? normalizedDescription = _normalizeOptional(description);
    final List<String> sanitizedTags = _sanitizeTags(tags);

    final formData = FormData();
    formData.fields.add(MapEntry('title', normalizedTitle));
    if (normalizedGenre != null) {
      formData.fields.add(MapEntry('genre', normalizedGenre));
    }
    if (normalizedDescription != null) {
      formData.fields.add(MapEntry('description', normalizedDescription));
    }
    for (final tag in sanitizedTags) {
      formData.fields.add(MapEntry('tags[]', tag));
    }
    formData.files.add(
      MapEntry(
        'audioFile',
        await MultipartFile.fromFile(
          filePath,
          filename: file.name,
        ),
      ),
    );

    final response = onProgress == null
        ? await dioClient.post(
            ApiConstants.tracks,
            data: formData,
            options: Options(contentType: 'multipart/form-data'),
          )
        : await dioClient.post(
            ApiConstants.tracks,
            data: formData,
            options: Options(contentType: 'multipart/form-data'),
            onSendProgress: (sent, total) {
              if (total <= 0) {
                onProgress(0);
                return;
              }

              final double progress = sent / total;
              onProgress(
                progress < 0 ? 0 : (progress > 1 ? 1 : progress),
              );
            },
          );

    final payload = _extractPayloadMap(response);

    final String trackId =
        (payload['trackId'] ?? payload['track_id'] ?? payload['id'] ?? '')
            .toString();

    if (trackId.isEmpty) {
      throw const FormatException('Upload response did not include a trackId.');
    }

    final String status = (payload['status'] ?? 'PROCESSING').toString();
    final String? secretToken = payload['secretToken']?.toString() ??
        payload['secret_token']?.toString();

    return UploadTrackResult(
      trackId: trackId,
      status: status,
      secretToken: secretToken,
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
      throw const FormatException(
        'Track status response did not include status.',
      );
    }

    return status;
  }
}

Map<String, dynamic> _extractPayloadMap(dynamic response) {
  final dynamic data =
      response is Map<String, dynamic> ? response : response.data;

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

String? _normalizeOptional(String? value) {
  final String normalized = (value ?? '').trim();
  return normalized.isEmpty ? null : normalized;
}

List<String> _sanitizeTags(List<String> tags) {
  final List<String> result = <String>[];
  final Set<String> seen = <String>{};

  for (final rawTag in tags) {
    final String trimmed = rawTag.trim();
    final String normalized = trimmed.toLowerCase();

    if (trimmed.isEmpty || seen.contains(normalized)) {
      continue;
    }

    if (result.length >= 10) {
      break;
    }

    result.add(trimmed);
    seen.add(normalized);
  }

  return result;
}
