// features/playback/data/repositories/queue_repository.dart

import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/core/network/api_constants.dart';

class QueueRepository {
  final DioClient _dio;
  QueueRepository(this._dio);

  /// POST /api/v1/player/queue/load
  /// يحمّل queue جديدة ويبدأ من trackIndex
  Future<void> loadQueue({
    required List<String> trackIds,
    required int startIndex,
    String source = 'app',
  }) async {
    await _dio.post(
      ApiConstants.queueLoad,
      data: {
        'track_ids': trackIds,
        'start_index': startIndex,
        'source': source,
      },
    );
  }

  Future<Track?> next() async {
  final res = await _dio.post<Map<String, dynamic>>(ApiConstants.queueNext);
  final data = res.data;
  if (data == null || data['track'] == null) return null;
  return Track.fromJson(data['track'] as Map<String, dynamic>);
}

Future<Track?> previous() async {
  final res = await _dio.post<Map<String, dynamic>>(ApiConstants.queuePrevious);
  final data = res.data;
  if (data == null || data['track'] == null) return null;
  return Track.fromJson(data['track'] as Map<String, dynamic>);
}

Future<Track?> jumpTo(int index) async {
  final res = await _dio.post<Map<String, dynamic>>(
    ApiConstants.queueJump,
    data: {'index': index},
  );
  final data = res.data;
  if (data == null || data['track'] == null) return null;
  return Track.fromJson(data['track'] as Map<String, dynamic>);
}
}