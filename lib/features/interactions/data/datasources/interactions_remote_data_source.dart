import 'dart:convert';

import '../../../../core/network/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../upload/data/dto/managed_track_dto.dart';
import '../dto/interaction_status_dto.dart';
import '../dto/paginated_engagement_users_dto.dart';

abstract class InteractionsRemoteDataSource {
  Future<void> likeTrack(String trackId);
  Future<void> unlikeTrack(String trackId);
  Future<void> repostTrack(String trackId);
  Future<void> unrepostTrack(String trackId);
  Future<InteractionStatusDto> getTrackInteractionStatus(String trackId);

  Future<PaginatedEngagementUsersDto> getTrackLikers(
    String trackId, {
    int page = 1,
    int limit = 20,
  });

  Future<PaginatedEngagementUsersDto> getTrackReposters(
    String trackId, {
    int page = 1,
    int limit = 20,
  });

  Future<List<ManagedTrackDto>> getMyLikedTracks();

  Future<List<ManagedTrackDto>> getMyRepostedTracks();
}

class InteractionsRemoteDataSourceImpl implements InteractionsRemoteDataSource {
  final DioClient dioClient;

  InteractionsRemoteDataSourceImpl(this.dioClient);

  @override
  Future<void> likeTrack(String trackId) async {
    await dioClient.post(ApiConstants.likeTrackPath(trackId));
  }

  @override
  Future<void> unlikeTrack(String trackId) async {
    await dioClient.delete(ApiConstants.likeTrackPath(trackId));
  }

  @override
  Future<void> repostTrack(String trackId) async {
    await dioClient.post(ApiConstants.repostTrackPath(trackId));
  }

  @override
  Future<void> unrepostTrack(String trackId) async {
    await dioClient.delete(ApiConstants.repostTrackPath(trackId));
  }

  @override
  Future<InteractionStatusDto> getTrackInteractionStatus(String trackId) async {
    final response = await dioClient.get(
      ApiConstants.trackInteractionStatusPath(trackId),
    );

    final responseData =
        response.data is String ? jsonDecode(response.data) : response.data;

    final raw = responseData['data'] ?? responseData;

    return InteractionStatusDto.fromJson(
      Map<String, dynamic>.from(raw as Map),
    );
  }

  @override
  Future<PaginatedEngagementUsersDto> getTrackLikers(
    String trackId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await dioClient.get(
      ApiConstants.trackLikersPath(trackId),
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );

    final responseData =
        response.data is String ? jsonDecode(response.data) : response.data;

    final raw = responseData['data'] ?? responseData;

    return PaginatedEngagementUsersDto.fromJson(
      Map<String, dynamic>.from(raw as Map),
    );
  }

  @override
  Future<PaginatedEngagementUsersDto> getTrackReposters(
    String trackId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await dioClient.get(
      ApiConstants.trackRepostersPath(trackId),
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );

    final responseData =
        response.data is String ? jsonDecode(response.data) : response.data;

    final raw = responseData['data'] ?? responseData;

    return PaginatedEngagementUsersDto.fromJson(
      Map<String, dynamic>.from(raw as Map),
    );
  }

  @override
  Future<List<ManagedTrackDto>> getMyLikedTracks() async {
    final response = await dioClient.get(ApiConstants.myLikedTracks);

    final responseData =
        response.data is String ? jsonDecode(response.data) : response.data;

    return _extractInteractionTrackDtos(responseData);
  }

  @override
  Future<List<ManagedTrackDto>> getMyRepostedTracks() async {
    final response = await dioClient.get(ApiConstants.myRepostedTracks);

    final responseData =
        response.data is String ? jsonDecode(response.data) : response.data;

    return _extractInteractionTrackDtos(responseData);
  }

  List<ManagedTrackDto> _extractInteractionTrackDtos(dynamic responseData) {
    final List<dynamic> rawItems = _extractItemsList(responseData);

    return rawItems
        .whereType<Map<String, dynamic>>()
        .map((item) {
          final dynamic rawTrack = item['track'];

          if (rawTrack is Map<String, dynamic>) {
            return ManagedTrackDto.fromJson(rawTrack);
          }

          // fallback لو الـ API رجعت التراك مباشرة
          return ManagedTrackDto.fromJson(item);
        })
        .toList(growable: false);
  }

  List<dynamic> _extractItemsList(dynamic responseData) {
    if (responseData is List<dynamic>) {
      return responseData;
    }

    if (responseData is Map<String, dynamic>) {
      final dynamic items = responseData['items'];
      if (items is List<dynamic>) {
        return items;
      }

      final dynamic data = responseData['data'];
      if (data is List<dynamic>) {
        return data;
      }

      if (data is Map<String, dynamic>) {
        final dynamic nestedItems = data['items'];
        if (nestedItems is List<dynamic>) {
          return nestedItems;
        }

        final dynamic nestedTracks =
            data['tracks'] ?? data['results'] ?? data['collection'];
        if (nestedTracks is List<dynamic>) {
          return nestedTracks;
        }
      }

      final dynamic directTracks =
          responseData['tracks'] ?? responseData['results'] ?? responseData['collection'];
      if (directTracks is List<dynamic>) {
        return directTracks;
      }
    }

    return const <dynamic>[];
  }
}