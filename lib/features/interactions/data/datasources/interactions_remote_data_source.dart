import 'dart:convert';

import '../../../../core/network/api_constants.dart';
import '../../../../core/network/dio_client.dart';
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
}