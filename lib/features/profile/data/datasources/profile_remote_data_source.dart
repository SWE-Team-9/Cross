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

      return rawTracks
          .whereType<Map<String, dynamic>>()
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
}
