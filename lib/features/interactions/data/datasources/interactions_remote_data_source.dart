import 'dart:convert';

import '../../../../core/network/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../dto/interaction_status_dto.dart';

abstract class InteractionsRemoteDataSource {
  Future<void> likeTrack(String trackId);
  Future<void> unlikeTrack(String trackId);
  Future<void> repostTrack(String trackId);
  Future<void> unrepostTrack(String trackId);
  Future<InteractionStatusDto> getTrackInteractionStatus(String trackId);
}

class InteractionsRemoteDataSourceImpl
    implements InteractionsRemoteDataSource {
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
}