import 'package:soundcloud_clone/features/offline/data/repositories/offline_repository.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';

class FakeOfflineRepository implements OfflineRepository {
  final Map<String, String> _storage = {};
  final Map<String, Track> _trackDetails = {};
  final Map<String, PlaylistEntity> _playlists = {};

  @override
  late final DioClient dio;

  @override
  Future<String> downloadTrack(String trackId) async {
    final path = '/fake/$trackId.mp3';
    _storage[trackId] = path;
    return path;
  }

  @override
  Future<Track?> fetchTrackDetails(String trackId) async {
    return _trackDetails[trackId];
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

  @override
  Future<Map<String, Track>> getDownloadedTrackDetails() async {
    return _trackDetails;
  }

  @override
  Future<void> saveDownloadedTrackDetails(Map<String, Track> data) async {
    _trackDetails
      ..clear()
      ..addAll(data);
  }

  @override
  Future<Map<String, PlaylistEntity>> getDownloadedPlaylists() async {
    return _playlists;
  }

  @override
  Future<void> saveDownloadedPlaylists(Map<String, PlaylistEntity> data) async {
    _playlists
      ..clear()
      ..addAll(data);
  }
}
