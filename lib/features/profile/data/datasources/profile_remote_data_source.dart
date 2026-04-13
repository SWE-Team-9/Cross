import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../upload/data/dto/managed_track_dto.dart';
import '../../domain/repositories/profile_repository.dart';
import '../dto/profile_dto.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileDto> getProfile(String handle);
  Future<ProfileDto> getMyProfile();
  Future<List<ManagedTrackDto>> getUserTracks(String userId);
  Future<ProfileDto> updateProfile(Map<String, dynamic> body);
  Future<Map<String, String>> updateExternalLinks(
    Map<String, String> externalLinks,
  );
  Future<String> uploadProfileImage({
    required ProfileImageType imageType,
    required String filePath,
  });
  Future<bool> checkHandleAvailable(String handle);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final DioClient _dioClient;

  const ProfileRemoteDataSourceImpl(this._dioClient);

  @override
  Future<ProfileDto> getProfile(String handle) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.profileByHandlePath(handle),
      );

      final responseData =
          response.data is String ? jsonDecode(response.data) : response.data;

      final Map<String, dynamic> profileMap =
          responseData['profile'] ?? responseData['data'] ?? responseData;

      return ProfileDto.fromJson(profileMap);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<ProfileDto> getMyProfile() async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.myProfile,
      );

      final responseData =
          response.data is String ? jsonDecode(response.data) : response.data;

      final Map<String, dynamic> profileMap =
          responseData['profile'] ?? responseData['data'] ?? responseData;

      return ProfileDto.fromJson(profileMap);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<ManagedTrackDto>> getUserTracks(String userId) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.userTracksPath(userId),
      );

      final dynamic responseData =
          response.data is String ? jsonDecode(response.data) : response.data;
      final List<dynamic> rawTracks = _extractTrackList(responseData);
      final List<Map<String, dynamic>> normalizedTracks = rawTracks
          .whereType<Map<String, dynamic>>()
          .map(_normalizeTrackPayload)
          .toList(growable: false);
      final List<Map<String, dynamic>> enrichedTracks = await Future.wait(
        normalizedTracks.map(_enrichTrackMetadataIfMissing),
      );

      return enrichedTracks
          .map(ManagedTrackDto.fromJson)
          .toList(growable: false);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<ProfileDto> updateProfile(Map<String, dynamic> body) async {
    try {
      final response = await _dioClient.dio.patch(
        ApiConstants.myProfile,
        data: body,
      );

      final responseData =
          response.data is String ? jsonDecode(response.data) : response.data;
      final Map<String, dynamic> profileMap =
          responseData['profile'] ?? responseData['data'] ?? responseData;

      return ProfileDto.fromJson(profileMap);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, String>> updateExternalLinks(
    Map<String, String> externalLinks,
  ) async {
    try {
      final entries = externalLinks.entries.toList();

      final body = <String, dynamic>{
        'links': List<Map<String, dynamic>>.generate(
          entries.length,
          (index) => {
            'platform': entries[index].key,
            'url': entries[index].value,
            'sort_order': index,
          },
        ),
      };

      final response = await _dioClient.dio.put(
        ApiConstants.profileLinks,
        data: body,
      );

      final responseData =
          response.data is String ? jsonDecode(response.data) : response.data;

      final dynamic rawLinks;
      if (responseData is List) {
        rawLinks = responseData;
      } else if (responseData is Map<String, dynamic>) {
        if (responseData.containsKey('links')) {
          rawLinks = responseData['links'];
        } else if (responseData.containsKey('data')) {
          rawLinks = responseData['data'];
        } else {
          rawLinks = responseData;
        }
      } else {
        rawLinks = null;
      }

      final parsed = _parseLinksMap(rawLinks);

      if (parsed.isEmpty && externalLinks.isNotEmpty) {
        return Map<String, String>.from(externalLinks);
      }

      return parsed;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String> uploadProfileImage({
    required ProfileImageType imageType,
    required String filePath,
  }) async {
    try {
      final String typeString =
          imageType == ProfileImageType.AVATAR ? 'avatar' : 'cover';

      final FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });

      final response = await _dioClient.dio.post(
        '${ApiConstants.profileImages}/$typeString',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final dynamic responseData =
          response.data is String ? jsonDecode(response.data) : response.data;

      if (responseData is Map<String, dynamic>) {
        final dynamic directUrl = responseData['url'];
        if (directUrl is String && directUrl.trim().isNotEmpty) {
          return directUrl;
        }

        final dynamic nestedData = responseData['data'];
        if (nestedData is Map<String, dynamic>) {
          final dynamic nestedUrl = nestedData['url'];
          if (nestedUrl is String && nestedUrl.trim().isNotEmpty) {
            return nestedUrl;
          }
        }
      }

      throw const FormatException(
        'Invalid upload response: missing image url.',
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> checkHandleAvailable(String handle) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.checkHandle,
        queryParameters: {'handle': handle},
      );

      final responseData =
          response.data is String ? jsonDecode(response.data) : response.data;
      return responseData['available'] as bool;
    } catch (e) {
      rethrow;
    }
  }

  Map<String, String> _parseLinksMap(dynamic rawLinks) {
    if (rawLinks is Map<String, dynamic>) {
      return rawLinks.map(
        (k, v) => MapEntry(
          k.toString().trim().toLowerCase(),
          v.toString(),
        ),
      );
    }

    if (rawLinks is List) {
      final Map<String, String> parsed = {};
      for (final item in rawLinks) {
        if (item is Map<String, dynamic>) {
          final platform =
              (item['platform'] ?? '').toString().trim().toLowerCase();
          final url = (item['url'] ?? '').toString().trim();
          if (platform.isNotEmpty && url.isNotEmpty) {
            parsed[platform] = url;
          }
        }
      }
      return parsed;
    }

    return {};
  }

  List<dynamic> _extractTrackList(dynamic responseData) {
    if (responseData is List<dynamic>) {
      return responseData;
    }

    if (responseData is Map<String, dynamic>) {
      final dynamic tracks = responseData['tracks'] ??
          responseData['data'] ??
          responseData['items'] ??
          responseData['results'];

      if (tracks is List<dynamic>) {
        return tracks;
      }
    }

    return const <dynamic>[];
  }

  Map<String, dynamic> _normalizeTrackPayload(Map<String, dynamic> rawTrack) {
    final dynamic nestedTrack = rawTrack['track'];

    if (nestedTrack is! Map<String, dynamic>) {
      return rawTrack;
    }

    final Map<String, dynamic> normalized = Map<String, dynamic>.from(
      nestedTrack,
    );

    for (final entry in rawTrack.entries) {
      normalized.putIfAbsent(entry.key, () => entry.value);
    }

    return normalized;
  }

  Future<Map<String, dynamic>> _enrichTrackMetadataIfMissing(
    Map<String, dynamic> track,
  ) async {
    if (_hasMetadataFields(track)) {
      return track;
    }

    final String trackId = (track['id'] ?? track['trackId'] ?? '').toString();
    if (trackId.isEmpty) {
      return track;
    }

    try {
      final response =
          await _dioClient.dio.get('${ApiConstants.tracks}/$trackId');
      final dynamic responseData =
          response.data is String ? jsonDecode(response.data) : response.data;
      final Map<String, dynamic>? detailTrack =
          _extractSingleTrackMap(responseData);
      if (detailTrack == null) {
        return track;
      }

      final Map<String, dynamic> normalizedDetail =
          _normalizeTrackPayload(detailTrack);
      final Map<String, dynamic> merged = Map<String, dynamic>.from(
        normalizedDetail,
      );

      for (final entry in track.entries) {
        merged.putIfAbsent(entry.key, () => entry.value);
      }

      return merged;
    } catch (_) {
      return track;
    }
  }

  Map<String, dynamic>? _extractSingleTrackMap(dynamic responseData) {
    if (responseData is! Map<String, dynamic>) {
      return null;
    }

    final dynamic track = responseData['track'];
    if (track is Map<String, dynamic>) {
      return track;
    }

    final dynamic data = responseData['data'];
    if (data is Map<String, dynamic>) {
      final dynamic nestedTrack = data['track'];
      if (nestedTrack is Map<String, dynamic>) {
        return nestedTrack;
      }
      return data;
    }

    return responseData;
  }

  bool _hasMetadataFields(Map<String, dynamic> track) {
    final String description = (track['description'] ??
            track['track_description'] ??
            track['trackDescription'] ??
            '')
        .toString()
        .trim();
    if (description.isNotEmpty) {
      return true;
    }

    final dynamic directTags = track['tags'] ??
        track['tag_list'] ??
        track['tagList'] ??
        track['track_tags'] ??
        track['trackTags'];
    if (_hasAnyTags(directTags)) {
      return true;
    }

    final dynamic metadata =
        track['metadata'] ?? track['track_metadata'] ?? track['trackMetadata'];
    final Map<String, dynamic>? metadataMap = _toMap(metadata);
    if (metadataMap == null) {
      return false;
    }

    final String metadataDescription = (metadataMap['description'] ??
            metadataMap['track_description'] ??
            metadataMap['trackDescription'] ??
            '')
        .toString()
        .trim();
    if (metadataDescription.isNotEmpty) {
      return true;
    }

    final dynamic metadataTags = metadataMap['tags'] ??
        metadataMap['tag_list'] ??
        metadataMap['tagList'] ??
        metadataMap['track_tags'] ??
        metadataMap['trackTags'];
    return _hasAnyTags(metadataTags);
  }

  bool _hasAnyTags(dynamic value) {
    if (value is List) {
      return value.isNotEmpty;
    }

    if (value is String) {
      return value
          .split(',')
          .map((item) => item.trim())
          .any((item) => item.isNotEmpty);
    }

    return false;
  }

  Map<String, dynamic>? _toMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is String) {
      try {
        final dynamic decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {}
    }

    return null;
  }
}
