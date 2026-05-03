import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:soundcloud_clone/core/models/track.dart';
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

  Future<List<PlaylistDto>> getTopPlaylists({
    int limit = 10,
  });

  Future<PlaylistDto> createPlaylist({
    required String title,
    required String description,
    required PlaylistVisibility visibility,
    List<String> initialTrackIds = const <String>[],
    String? genre,
  });

  Future<PlaylistDto> getPlaylistDetails(
    String playlistId, {
    int? limit,
    int? offset,
  });

  Future<PlaylistDto> getPlaylistEditDetails(String playlistId);

  Future<void> updatePlaylist({
    required String playlistId,
    String? title,
    String? description,
    PlaylistVisibility? visibility,
    String? genre,
    String? playlistType,
    DateTime? releaseDate,
    List<String>? tags,
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

  Future<void> recordPlaylistPlayback(String playlistId);

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

  Future<String> getPlaylistEmbedCode(
    String playlistId, {
    String? theme,
    bool? autoplay,
    int? start,
    bool? hideArtwork,
    int? width,
    int? height,
  });
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
  }) async {
    final response = await dioClient.get(
      ApiConstants.recentPlaylists,
      queryParameters: {'limit': limit},
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
  Future<List<PlaylistDto>> getTopPlaylists({
    int limit = 10,
  }) async {
    final response = await dioClient.get(
      ApiConstants.topPlaylists,
      queryParameters: {'limit': limit},
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
  Future<PlaylistDto> createPlaylist({
    required String title,
    required String description,
    required PlaylistVisibility visibility,
    List<String> initialTrackIds = const <String>[],
    String? genre,
  }) async {
    final response = await dioClient.post(
      ApiConstants.playlistsBase,
      data: {
        'title': title,
        'description': description,
        'visibility': visibility.apiValue,
        'trackIds': initialTrackIds,
        if (genre != null && genre.trim().isNotEmpty) 'genre': genre.trim(),
      },
    );

    final payload = _decode(response.data);
    final data = _extractData(payload);

    return PlaylistDto.fromJson(_asMap(data));
  }

  @override
  Future<PlaylistDto> getPlaylistDetails(
    String playlistId, {
    int? limit,
    int? offset,
  }) async {
    final queryParameters = <String, dynamic>{
      if (limit != null) 'limit': limit,
      if (offset != null) 'offset': offset,
    };

    final response = await dioClient.get(
      ApiConstants.playlistByIdPath(playlistId),
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    final payload = _decode(response.data);
    final data = _extractData(payload);

    return _enrichPlaylistTracks(PlaylistDto.fromJson(_asMap(data)));
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
    String? genre,
    String? playlistType,
    DateTime? releaseDate,
    List<String>? tags,
  }) async {
    await dioClient.patch(
      ApiConstants.playlistByIdPath(playlistId),
      data: {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (visibility != null) 'visibility': visibility.apiValue,
        if (genre != null && genre.trim().isNotEmpty) 'genre': genre.trim(),
        if (playlistType != null) 'type': playlistType,
        if (releaseDate != null) 'releaseDate': _formatReleaseDate(releaseDate),
        if (tags != null) 'tags': tags,
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
      final dynamic url = data['url'] ??
          data['coverImageUrl'] ??
          data['cover_image_url'] ??
          data['coverUrl'] ??
          data['cover_url'] ??
          data['image'];
      if (url != null && url.toString().trim().isNotEmpty) {
        return url.toString();
      }
    }

    if (payload is Map<String, dynamic>) {
      final dynamic url = payload['url'] ??
          payload['coverImageUrl'] ??
          payload['cover_image_url'] ??
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
      ApiConstants.globalSearch,
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
  Future<void> recordPlaylistPlayback(String playlistId) async {
    await dioClient.post(ApiConstants.playlistPlayPath(playlistId));
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

    return _enrichPlaylistTracks(PlaylistDto.fromJson(_asMap(data)));
  }

  @override
  Future<String> getPlaylistEmbedCode(
    String playlistId, {
    String? theme,
    bool? autoplay,
    int? start,
    bool? hideArtwork,
    int? width,
    int? height,
  }) async {
    final queryParameters = <String, dynamic>{
      if (theme != null) 'theme': theme,
      if (autoplay != null) 'autoplay': autoplay,
      if (start != null) 'start': start,
      if (hideArtwork != null) 'hideArtwork': hideArtwork,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
    };

    final response = await dioClient.get(
      ApiConstants.playlistEmbedPath(playlistId),
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
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

  Future<PlaylistDto> _enrichPlaylistTracks(PlaylistDto playlist) async {
    if (playlist.tracks.isEmpty) return playlist;

    final enrichedTracks = await Future.wait(
      playlist.tracks.map((track) async {
        if (!_needsTrackDetails(track)) return track;
        return _loadTrackDetails(track);
      }),
    );

    return PlaylistDto(
      playlistId: playlist.playlistId,
      title: playlist.title,
      description: playlist.description,
      visibility: playlist.visibility,
      genre: playlist.genre,
      genreId: playlist.genreId,
      slug: playlist.slug,
      playlistType: playlist.playlistType,
      releaseDate: playlist.releaseDate,
      tags: playlist.tags,
      secretToken: playlist.secretToken,
      coverImageUrl: playlist.coverImageUrl,
      owner: playlist.owner,
      tracks: enrichedTracks,
      tracksCount: playlist.tracksCount,
      likesCount: playlist.likesCount,
      isLiked: playlist.isLiked,
    );
  }

  bool _needsTrackDetails(Track track) {
    final normalizedArtist = track.artist.trim().toLowerCase();
    return normalizedArtist.isEmpty ||
        normalizedArtist == 'unknown artist' ||
        normalizedArtist == 'unkown artist';
  }

  Future<Track> _loadTrackDetails(Track track) async {
    try {
      final response =
          await dioClient.get(ApiConstants.trackByIdPath(track.id));
      final payload = _decode(response.data);
      final data = _asMap(_extractData(payload));
      if (data.isEmpty) return track;

      return track.copyWith(
        title: _asNonEmptyString(data['title']) ?? track.title,
        artist: _extractArtistName(data) ?? track.artist,
        audioUrl: _asNonEmptyString(data['audioUrl'] ?? data['streamUrl']) ??
            track.audioUrl,
        artworkUrl: _asNonEmptyString(
              data['coverArtUrl'] ??
                  data['cover_art_url'] ??
                  data['artworkUrl'] ??
                  data['artwork_url'],
            ) ??
            track.artworkUrl,
        handle: _extractArtistHandle(data) ?? track.handle,
        artistId: _extractArtistId(data) ?? track.artistId,
        likesCount: _asIntValue(data['likesCount'] ?? data['likes_count']) ??
            track.likesCount,
        repostsCount:
            _asIntValue(data['repostsCount'] ?? data['reposts_count']) ??
                track.repostsCount,
        durationMs: _asIntValue(data['durationMs'] ?? data['duration_ms']) ??
            track.durationMs,
      );
    } catch (_) {
      return track;
    }
  }
}

String _formatReleaseDate(DateTime releaseDate) {
  final iso = releaseDate.toIso8601String();
  final datePart = iso.split('T').first;
  return datePart.isEmpty ? iso : datePart;
}

dynamic _decode(dynamic responseData) {
  if (responseData is String) {
    return jsonDecode(responseData);
  }
  return responseData;
}

dynamic _extractData(dynamic payload) {
  if (payload is Map<String, dynamic>) {
    final data = payload['data'];
    if (data != null) return data;

    final playlist = payload['playlist'];
    if (playlist != null) return playlist;

    return payload;
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
      final nested = data['topPlaylists'] ??
          data['playlists'] ??
          data['items'] ??
          data['results'] ??
          data['data'];
      if (nested is List) return nested;

      final grouped = _extractGroupedGenrePlaylists(data);
      if (grouped.isNotEmpty) return grouped;
    }

    final direct = payload['topPlaylists'] ??
        payload['playlists'] ??
        payload['items'] ??
        payload['results'];
    if (direct is List) return direct;

    final grouped = _extractGroupedGenrePlaylists(payload);
    if (grouped.isNotEmpty) return grouped;
  }

  return const <dynamic>[];
}

List<dynamic> _extractGroupedGenrePlaylists(Map<String, dynamic> payload) {
  final rawGenres = payload['genres'];
  if (rawGenres is! List) return const <dynamic>[];

  final playlists = <dynamic>[];

  for (final rawGroup in rawGenres) {
    final group = _asMap(rawGroup);
    if (group.isEmpty) continue;

    final genre = _asNonEmptyString(
      group['genre'] ??
          group['genreName'] ??
          group['genre_name'] ??
          group['name'] ??
          group['slug'],
    );

    final rawPlaylists =
        group['playlists'] ?? group['items'] ?? group['results'];

    if (rawPlaylists is! List) continue;

    for (final rawPlaylist in rawPlaylists) {
      final playlist = _asMap(rawPlaylist);
      if (playlist.isEmpty) {
        playlists.add(rawPlaylist);
        continue;
      }

      final hasGenre = _asNonEmptyString(
            playlist['genre'] ??
                playlist['genreSlug'] ??
                playlist['genre_slug'],
          ) !=
          null;

      playlists.add(
        genre == null || hasGenre
            ? playlist
            : <String, dynamic>{
                ...playlist,
                'genre': genre,
              },
      );
    }
  }

  return playlists;
}

String? _extractArtistName(Map<String, dynamic> json) {
  final rawArtist = json['artist'];
  final artistMap = rawArtist is Map ? _asMap(rawArtist) : <String, dynamic>{};
  final uploaderMap = _asMap(
    json['uploader'] ?? json['user'] ?? json['owner'],
  );

  return _asNonEmptyString(
    json['artistName'] ??
        json['artist_name'] ??
        json['uploaderName'] ??
        json['uploader_name'] ??
        (rawArtist is String ? rawArtist : null) ??
        artistMap['displayName'] ??
        artistMap['display_name'] ??
        artistMap['name'] ??
        artistMap['username'] ??
        uploaderMap['displayName'] ??
        uploaderMap['display_name'] ??
        uploaderMap['username'],
  );
}

String? _extractArtistHandle(Map<String, dynamic> json) {
  final artistMap = _asMap(json['artist']);
  final uploaderMap = _asMap(
    json['uploader'] ?? json['user'] ?? json['owner'],
  );

  return _asNonEmptyString(
    json['artistHandle'] ??
        json['artist_handle'] ??
        artistMap['handle'] ??
        artistMap['username'] ??
        uploaderMap['handle'] ??
        uploaderMap['username'],
  );
}

String? _extractArtistId(Map<String, dynamic> json) {
  final artistMap = _asMap(json['artist']);
  final uploaderMap = _asMap(
    json['uploader'] ?? json['user'] ?? json['owner'],
  );

  return _asNonEmptyString(
    json['artistId'] ??
        json['artist_id'] ??
        artistMap['id'] ??
        artistMap['userId'] ??
        artistMap['user_id'] ??
        uploaderMap['id'] ??
        uploaderMap['userId'] ??
        uploaderMap['user_id'],
  );
}

String? _asNonEmptyString(dynamic value) {
  final parsed = value?.toString().trim() ?? '';
  return parsed.isEmpty ? null : parsed;
}

int? _asIntValue(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
