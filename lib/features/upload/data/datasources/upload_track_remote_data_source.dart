import 'dart:io';
import 'package:dio/dio.dart';

class UploadTrackRemoteDataSource {
  final Dio dio;

  UploadTrackRemoteDataSource(this.dio);

  String get _basePath => '/api/v1/tracks';

  Future<Map<String, dynamic>> uploadTrack({
    required String title,
    required String genre,
    required List<String> tags,
    required DateTime releaseDate,
    required File audioFile,
    String? description,
  }) async {
    final formData = FormData.fromMap({
      "title": title,
      "genre": genre,
      "tags": tags,
      "releaseDate": releaseDate.toIso8601String().split("T").first,
      if (description != null) "description": description,
      "audioFile": await MultipartFile.fromFile(
        audioFile.path,
        filename: audioFile.path.split('/').last,
      ),
    });

    final response = await dio.post(
      _basePath,
      data: formData,
    );

    return response.data;
  }

  Future<Map<String, dynamic>> getTrackDetails(String trackId) async {
    final response = await dio.get('$_basePath/$trackId');
    return response.data;
  }

  Future<Map<String, dynamic>> getTrackStatus(String trackId) async {
    final response = await dio.get('$_basePath/$trackId/status');
    return response.data;
  }

  Future<void> updateTrackMetadata({
    required String trackId,
    required String title,
    required String genre,
    required List<String> tags,
    String? description,
    DateTime? releaseDate,
  }) async {
    final data = {
      "title": title,
      "genre": genre,
      "tags": tags,
      if (description != null) "description": description,
      if (releaseDate != null)
        "releaseDate": releaseDate.toIso8601String().split("T").first,
    };

    await dio.put('$_basePath/$trackId', data: data);
  }

  Future<void> deleteTrack(String trackId) async {
    await dio.delete('$_basePath/$trackId');
  }
}