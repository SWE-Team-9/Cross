import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:soundcloud_clone/core/network/api_constants.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/features/playlists/data/dto/playlist_dto.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';

abstract class PlaylistsRemoteDataSource {
  Future<List<PlaylistDto>> getMyPlaylists({
    int page = 1,
    int limit = 20,
  });

  Future<List<PlaylistDto>> getRecentPlaylists({
    int limit = 10,
  });

  Future<PlaylistDto> createPlaylist({
    required String title,
    required String description,
    required PlaylistVisibility visibility,
    List<String> initialTrackIds = const <String>[],
  });

  Future<PlaylistDto> getPlaylistDetails(String playlistId);

  Future<PlaylistDto> getPlaylistEditDetails(String playlistId);

  Future<void> updatePlaylist({
    required String playlistId,
    String? title,
    String? description,
    PlaylistVisibility? visibility,
  });

  Future<String?> uploadPlaylistCover({
    required String playlistId,
    required String filePath,
  });

  Future<void> deletePlaylist(String playlistId);

  Future<List<PlaylistDto>> getLikedPlaylists({
    int page = 1,
    int limit = 20,
  });

  Future<List<PlaylistDto>> searchPublicPlaylists(
    String query, {
    int page = 1,
    int limit = 20,
  });

  Future<void> likePlaylist(String playlistId);

  Future<void> unlikePlaylist(String playlistId);

  Future<void> addTrackToPlaylist({
    required String playlistId,
    required String trackId,
  });

  Future<void> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  });

  Future<void> reorderPlaylistTracks({
    required String playlistId,
    required List<String> orderedTrackIds,
  });

  Future<PlaylistDto> resolveSecretPlaylist(String secretToken);

  Future<String> getPlaylistEmbedCode(String playlistId);
}

class PlaylistsRemoteDataSourceImpl implements PlaylistsRemoteDataSource {
  final DioClient dioClient;

  PlaylistsRemoteDataSourceImpl(this.dioClient);

  @override
  Future<List<PlaylistDto>> getMyPlaylists({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await dioClient.get(
      ApiConstants.myPlaylists,
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );

    final payload = _decode(response.data);
    final data = _extractData(payload);

    final dynamic rawList;
    if (data is Map<String, dynamic>) {
      rawList = data['playlists'] ?? data['items'] ?? data['data'];
    } else {
      rawList = (payload is Map<String, dynamic>)
          ? payload['playlists'] ?? payload['items'] ?? payload['data']
          : payload;
    }

    if (rawList is! List) return const <PlaylistDto>[];

    return rawList
        .map((item) => PlaylistDto.fromJson(_asMap(item)))
        .where((playlist) => playlist.playlistId.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<List<PlaylistDto>> getRecentPlaylists({
    int limit = 10,
  }) {
    return getMyPlaylists(page: 1, limit: limit);
  }

  @override
  Future<PlaylistDto> createPlaylist({
    required String title,
    required String description,
    required PlaylistVisibility visibility,
    List<String> initialTrackIds = const <String>[],
  }) async {
    final response = await dioClient.post(
      ApiConstants.playlistsBase,
      data: {
        'title': title,
        'description': description,
        'visibility': visibility.apiValue,
        'trackIds': initialTrackIds,
      },
    );

    final payload = _decode(response.data);
    final data = _extractData(payload);

    return PlaylistDto.fromJson(_asMap(data));
  }

  @override
  Future<PlaylistDto> getPlaylistDetails(String playlistId) async {
    final response = await dioClient.get(
      ApiConstants.playlistByIdPath(playlistId),
    );

    final payload = _decode(response.data);
    final data = _extractData(payload);

    return PlaylistDto.fromJson(_asMap(data));
  }

  @override
  Future<PlaylistDto> getPlaylistEditDetails(String playlistId) async {
    final response = await dioClient.get(
      ApiConstants.playlistEditPath(playlistId),
    );

    final payload = _decode(response.data);
    final data = _extractData(payload);

    return PlaylistDto.fromJson(_asMap(data));
  }

  @override
  Future<void> updatePlaylist({
    required String playlistId,
    String? title,
    String? description,
    PlaylistVisibility? visibility,
  }) async {
    await dioClient.patch(
      ApiConstants.playlistByIdPath(playlistId),
      data: {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (visibility != null) 'visibility': visibility.apiValue,
      },
    );
  }

  @override
  Future<String?> uploadPlaylistCover({
    required String playlistId,
    required String filePath,
  }) async {
    final FormData formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });

    final response = await dioClient.dio.post(
      ApiConstants.playlistCoverPath(playlistId),
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final payload = _decode(response.data);
    final data = _extractData(payload);

    if (data is Map<String, dynamic>) {
      final dynamic url =
          data['url'] ?? data['coverUrl'] ?? data['cover_url'] ?? data['image'];
      if (url != null && url.toString().trim().isNotEmpty) {
        return url.toString();
      }
    }

    if (payload is Map<String, dynamic>) {
      final dynamic url = payload['url'] ??
          payload['coverUrl'] ??
          payload['cover_url'] ??
          payload['image'];
      if (url != null && url.toString().trim().isNotEmpty) {
        return url.toString();
      }
    }

    return null;
  }

  @override
  Future<void> deletePlaylist(String playlistId) async {
    await dioClient.delete(ApiConstants.playlistByIdPath(playlistId));
  }

  @override
  Future<List<PlaylistDto>> getLikedPlaylists({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await dioClient.get(
      ApiConstants.myLikedPlaylists,
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );

    final payload = _decode(response.data);
    final rawList = _extractPlaylistList(payload);
    if (rawList.isEmpty) return const <PlaylistDto>[];

    return rawList
        .map((item) => PlaylistDto.fromJson(_asMap(item)))
        .where((playlist) => playlist.playlistId.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<List<PlaylistDto>> searchPublicPlaylists(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const <PlaylistDto>[];

    final response = await dioClient.get(
      ApiConstants.discoverySearchPath,
      queryParameters: {
        'q': trimmed,
        'type': 'playlists',
        'page': page,
        'limit': limit,
      },
    );

    final payload = _decode(response.data);
    final rawList = _extractPlaylistList(payload);
    if (rawList.isEmpty) return const <PlaylistDto>[];

    return rawList
        .map((item) => PlaylistDto.fromJson(_asMap(item)))
        .where((playlist) => playlist.playlistId.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<void> likePlaylist(String playlistId) async {
    await dioClient.post(ApiConstants.likePlaylistPath(playlistId));
  }

  @override
  Future<void> unlikePlaylist(String playlistId) async {
    await dioClient.delete(ApiConstants.likePlaylistPath(playlistId));
  }

  @override
  Future<void> addTrackToPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    await dioClient.post(
      ApiConstants.playlistTracksPath(playlistId),
      data: {
        'trackId': trackId,
      },
    );
  }

  @override
  Future<void> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    await dioClient.delete(
      ApiConstants.removeTrackFromPlaylistPath(playlistId, trackId),
    );
  }

  @override
  Future<void> reorderPlaylistTracks({
    required String playlistId,
    required List<String> orderedTrackIds,
  }) async {
    await dioClient.patch(
      ApiConstants.reorderPlaylistPath(playlistId),
      data: {
        'orderedTrackIds': orderedTrackIds,
      },
    );
  }

  @override
  Future<PlaylistDto> resolveSecretPlaylist(String secretToken) async {
    final response = await dioClient.get(
      ApiConstants.resolveSecretPlaylistPath(secretToken),
    );

    final payload = _decode(response.data);
    final data = _extractData(payload);

    return PlaylistDto.fromJson(_asMap(data));
  }

  @override
  Future<String> getPlaylistEmbedCode(String playlistId) async {
    final response = await dioClient.get(
      ApiConstants.playlistEmbedPath(playlistId),
    );

    final payload = _decode(response.data);
    final data = _extractData(payload);

    if (data is Map<String, dynamic>) {
      return (data['embedCode'] ?? data['embed_code'] ?? '').toString();
    }

    if (payload is Map<String, dynamic>) {
      return (payload['embedCode'] ?? payload['embed_code'] ?? '').toString();
    }

    return '';
  }
}

dynamic _decode(dynamic responseData) {
  if (responseData is String) {
    return jsonDecode(responseData);
  }
  return responseData;
}

dynamic _extractData(dynamic payload) {
  if (payload is Map<String, dynamic>) {
    return payload['data'] ?? payload;
  }
  return payload;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<dynamic> _extractPlaylistList(dynamic payload) {
  if (payload is List) return payload;

  if (payload is Map<String, dynamic>) {
    final data = payload['data'];
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final nested =
          data['playlists'] ?? data['items'] ?? data['results'] ?? data['data'];
      if (nested is List) return nested;
    }

    final direct =
        payload['playlists'] ?? payload['items'] ?? payload['results'];
    if (direct is List) return direct;
  }

  return const <dynamic>[];
}


