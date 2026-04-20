// coverage:ignore-file
import '../../../../core/models/track.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/dio_client.dart';

abstract class RecentlyPlayedRemoteDataSource {
  Future<List<Track>> getListeningHistory({int page = 1, int limit = 20});
  Future<void> recordTrackPlay(String trackId);
}

class RecentlyPlayedRemoteDataSourceImpl
    implements RecentlyPlayedRemoteDataSource {
  const RecentlyPlayedRemoteDataSourceImpl(this._dioClient);

  final DioClient _dioClient;

  @override
  Future<List<Track>> getListeningHistory(
      {int page = 1, int limit = 20}) async {
    final dynamic response = await _dioClient.get(
      ApiConstants.listeningHistoryPath,
      queryParameters: {'page': page, 'limit': limit},
    );

    final Map<String, dynamic> root = _asMap(response);
    final dynamic rawList = root['history'] ??
        root['listeningHistory'] ??
        root['items'] ??
        root['tracks'] ??
        (root['data'] is List ? root['data'] : null);

    if (rawList is! List) return const <Track>[];

    return rawList
        .map((item) => _parseTrack(_asMap(item)))
        .whereType<Track>()
        .toList(growable: false);
  }

  @override
  Future<void> recordTrackPlay(String trackId) async {
    await _dioClient.post(ApiConstants.playerTrackPlayPath(trackId));
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  Track? _parseTrack(Map<String, dynamic> json) {
    final String id =
        (json['id'] ?? json['trackId'] ?? json['track_id'] ?? '').toString();
    if (id.trim().isEmpty) return null;

    final dynamic uploader =
        json['uploader'] ?? json['artist'] ?? json['owner'];
    final Map<String, dynamic> uploaderMap = _asMap(uploader);

    final String title = (json['title'] ?? '').toString().trim();
    final String artist = (uploaderMap['displayName'] ??
            uploaderMap['username'] ??
            json['artistName'] ??
            '')
        .toString()
        .trim();
    final String handle =
        (uploaderMap['handle'] ?? uploaderMap['username'] ?? '')
            .toString()
            .trim();

    return Track(
      id: id,
      title: title.isEmpty ? 'Untitled' : title,
      artist: artist.isEmpty ? 'Unknown artist' : artist,
      audioUrl: '',
      artworkUrl:
          (json['coverArtUrl'] ?? json['cover_art_url'] ?? json['artworkUrl'])
              ?.toString(),
      handle: handle.isEmpty ? null : handle,
      likesCount: (json['likesCount'] as int?) ?? 0,
      repostsCount: (json['repostsCount'] as int?) ?? 0,
    );
  }
}
