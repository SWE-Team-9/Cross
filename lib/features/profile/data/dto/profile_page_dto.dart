import '../../../playlists/data/dto/playlist_dto.dart';
import '../../../playlists/domain/entities/playlist_entity.dart';
import '../../domain/entities/profile_page_data.dart';
import 'profile_dto.dart';

class ProfilePageDto {
  final ProfileDto profile;
  final List<PlaylistDto> playlists;
  final List<PlaylistDto> likedPlaylists;

  const ProfilePageDto({
    required this.profile,
    required this.playlists,
    required this.likedPlaylists,
  });

  factory ProfilePageDto.fromJson(Map<String, dynamic> json) {
    print('DEBUG ProfilePageDto: Parsing json with keys: ${json.keys}');
    final Map<String, dynamic> data = _asMap(json['data']);
    final Map<String, dynamic> source = data.isNotEmpty ? data : json;
    final Map<String, dynamic> profileMap = _extractProfileMap(source);

    final extractedPlaylists = _extractPlaylistDtos(
      source,
      const <String>[
        'playlists',
        'userPlaylists',
        'user_playlists',
        'createdPlaylists',
        'created_playlists',
      ],
    );
    print('DEBUG ProfilePageDto: Found ${extractedPlaylists.length} playlists from aggregate endpoint');

    final extractedLikedPlaylists = _extractPlaylistDtos(
      source,
      const <String>[
        'likedPlaylists',
        'liked_playlists',
        'userLikedPlaylists',
        'user_liked_playlists',
        'likes',
      ],
    );
    print('DEBUG ProfilePageDto: Found ${extractedLikedPlaylists.length} liked playlists from aggregate endpoint');

    return ProfilePageDto(
      profile: ProfileDto.fromJson(profileMap),
      playlists: extractedPlaylists,
      likedPlaylists: extractedLikedPlaylists,
    );
  }

  ProfilePageData toEntity() {
    return ProfilePageData(
      profile: profile.toEntity(),
      playlists: playlists.map(_playlistToEntity).toList(growable: false),
      likedPlaylists:
          likedPlaylists.map(_playlistToEntity).toList(growable: false),
    );
  }
}

Map<String, dynamic> _extractProfileMap(Map<String, dynamic> source) {
  final profileMap = _findFirstNestedMapByKeys(
    source,
    const <String>['profile', 'user'],
  );
  if (profileMap.isNotEmpty) {
    return profileMap;
  }

  return source;
}

List<PlaylistDto> _extractPlaylistDtos(
  Map<String, dynamic> source,
  List<String> keys,
) {
  final items = _findFirstNestedPlaylistListByKeys(source, keys);
  if (items.isEmpty) {
    return const <PlaylistDto>[];
  }

  return items
      .whereType<Map>()
      .map((item) => PlaylistDto.fromJson(Map<String, dynamic>.from(item)))
      .where((playlist) => playlist.playlistId.isNotEmpty)
      .toList(growable: false);
}

Map<String, dynamic> _findFirstNestedMapByKeys(
  Map<String, dynamic> source,
  List<String> keys,
) {
  for (final key in keys) {
    final candidate = _asMap(source[key]);
    if (candidate.isNotEmpty) {
      return candidate;
    }
  }

  for (final value in source.values) {
    final nestedMap = _asMap(value);
    if (nestedMap.isNotEmpty) {
      final nestedResult = _findFirstNestedMapByKeys(nestedMap, keys);
      if (nestedResult.isNotEmpty) {
        return nestedResult;
      }
    }

    final nestedList = _asList(value);
    for (final item in nestedList) {
      final itemMap = _asMap(item);
      if (itemMap.isEmpty) continue;

      final nestedResult = _findFirstNestedMapByKeys(itemMap, keys);
      if (nestedResult.isNotEmpty) {
        return nestedResult;
      }
    }
  }

  return <String, dynamic>{};
}

List<dynamic> _findFirstNestedPlaylistListByKeys(
  Map<String, dynamic> source,
  List<String> keys,
) {
  for (final key in keys) {
    final items = _extractPlaylistList(source[key]);
    if (items.isNotEmpty) {
      return items;
    }
  }

  for (final value in source.values) {
    final nestedMap = _asMap(value);
    if (nestedMap.isNotEmpty) {
      final nestedResult = _findFirstNestedPlaylistListByKeys(
        nestedMap,
        keys,
      );
      if (nestedResult.isNotEmpty) {
        return nestedResult;
      }
    }

    final nestedList = _asList(value);
    for (final item in nestedList) {
      final itemMap = _asMap(item);
      if (itemMap.isEmpty) continue;

      final nestedResult = _findFirstNestedPlaylistListByKeys(itemMap, keys);
      if (nestedResult.isNotEmpty) {
        return nestedResult;
      }
    }
  }

  return const <dynamic>[];
}

PlaylistEntity _playlistToEntity(PlaylistDto dto) => dto.toEntity();

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<dynamic> _asList(dynamic value) {
  if (value is List<dynamic>) return value;
  if (value is List) return List<dynamic>.from(value);
  return const <dynamic>[];
}

List<dynamic> _extractPlaylistList(dynamic value) {
  if (value is List<dynamic>) return value;
  if (value is List) return List<dynamic>.from(value);

  final map = _asMap(value);
  if (map.isEmpty) return const <dynamic>[];

  for (final key in const <String>[
    'items',
    'playlists',
    'results',
    'collection',
    'data',
  ]) {
    final nestedList = _asList(map[key]);
    if (nestedList.isNotEmpty) {
      return nestedList;
    }
  }

  return const <dynamic>[];
}
