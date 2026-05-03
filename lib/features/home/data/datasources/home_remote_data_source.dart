import 'dart:convert';

import 'package:soundcloud_clone/core/network/api_constants.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/features/home/domain/entities/home_content.dart';
import 'package:soundcloud_clone/features/playlists/data/dto/playlist_dto.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';

abstract class HomeRemoteDataSource {
  Future<HomeTopPlaylists> getTopPlaylists({int limit = 10});
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  const HomeRemoteDataSourceImpl(this._client);

  final DioClient _client;

  @override
  Future<HomeTopPlaylists> getTopPlaylists({int limit = 10}) async {
    final response = await _client.get(
      ApiConstants.topPlaylists,
      queryParameters: {'limit': limit},
    );

    final payload = _decode(response.data);
    final body = _asMap(_extractData(payload));

    return HomeTopPlaylists(
      overallPlaylists: _extractPlaylistList(
        body['topPlaylists'] ?? body['playlists'],
      ).map(_playlistFromRaw).whereType<PlaylistEntity>().toList(
            growable: false,
          ),
      genreGroups: _extractGenreGroups(body['genres']),
    );
  }

  List<HomeTopPlaylistGroup> _extractGenreGroups(dynamic rawGenres) {
    if (rawGenres is! List) return const <HomeTopPlaylistGroup>[];

    return rawGenres
        .map((rawGroup) {
          final group = _asMap(rawGroup);
          if (group.isEmpty) return null;

          final genre = _asNonEmptyString(
            group['genre'] ??
                group['genreName'] ??
                group['genre_name'] ??
                group['name'] ??
                group['slug'],
          );
          if (genre == null) return null;

          final playlists = _extractPlaylistList(
            group['playlists'] ?? group['items'] ?? group['results'],
          )
              .map((rawPlaylist) => _playlistFromRaw(rawPlaylist, genre: genre))
              .whereType<PlaylistEntity>()
              .toList(growable: false);

          if (playlists.isEmpty) return null;

          return HomeTopPlaylistGroup(
            genre: genre,
            playlists: playlists,
          );
        })
        .whereType<HomeTopPlaylistGroup>()
        .toList(growable: false);
  }

  PlaylistEntity? _playlistFromRaw(dynamic raw, {String? genre}) {
    final map = _asMap(raw);
    if (map.isEmpty) return null;

    final hasGenre = _asNonEmptyString(
          map['genre'] ?? map['genreSlug'] ?? map['genre_slug'],
        ) !=
        null;

    final dto = PlaylistDto.fromJson(
      genre == null || hasGenre
          ? map
          : <String, dynamic>{
              ...map,
              'genre': genre,
            },
    );

    if (dto.playlistId.isEmpty) return null;
    return dto.toEntity();
  }

  dynamic _decode(dynamic responseData) {
    if (responseData is String) return jsonDecode(responseData);
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

  List<dynamic> _extractPlaylistList(dynamic value) {
    return value is List ? value : const <dynamic>[];
  }

  String? _asNonEmptyString(dynamic value) {
    final parsed = value?.toString().trim() ?? '';
    return parsed.isEmpty ? null : parsed;
  }
}
