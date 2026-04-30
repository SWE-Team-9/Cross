import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:dio/dio.dart';

class OfflineRepository {
  final DioClient dio;

  OfflineRepository(this.dio);

  Future<String> downloadTrack(String trackId) async {
    // STEP 1: entitlement check
    await dio.get('/api/v1/subscriptions/offline/$trackId');

    // STEP 2: download audio bytes

    final response = await dio.get(
      '/api/v1/subscriptions/offline/$trackId/stream',
      options: Options(responseType: ResponseType.bytes),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$trackId.mp3');

    await file.writeAsBytes(response.data);

    return file.path;
  }
}
