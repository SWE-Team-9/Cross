import 'package:soundcloud_clone/features/offline/data/repositories/offline_repository.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';

class FakeOfflineRepository implements OfflineRepository {
  final Map<String, String> _storage = {};

  @override
  late final DioClient dio;

  @override
  Future<String> downloadTrack(String trackId) async {
    final path = '/fake/$trackId.mp3';
    _storage[trackId] = path;
    return path;
  }

  @override
  Future<Map<String, String>> getDownloadedTracks() async {
    return _storage;
  }

  @override
  Future<void> saveDownloadedTracks(Map<String, String> data) async {
    _storage
      ..clear()
      ..addAll(data);
  }
}
