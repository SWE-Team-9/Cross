import 'dart:convert';

import '../../../../core/network/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../dto/comment_dto.dart';

abstract class CommentsRemoteDataSource {
  Future<List<CommentDto>> getTrackComments(String trackId);
  Future<CommentDto> createComment({
    required String trackId,
    required String content,
    String? parentCommentId,
    int? timestampSeconds,
  });
  Future<void> deleteComment(String commentId);
}

class CommentsRemoteDataSourceImpl implements CommentsRemoteDataSource {
  final DioClient dioClient;

  CommentsRemoteDataSourceImpl(this.dioClient);

  @override
  Future<List<CommentDto>> getTrackComments(String trackId) async {
    final response =
        await dioClient.get(ApiConstants.trackCommentsPath(trackId));

    final responseData =
        response.data is String ? jsonDecode(response.data) : response.data;

    List<dynamic> rawList;

    if (responseData is List) {
      rawList = responseData;
    } else if (responseData is Map<String, dynamic>) {
      final dynamic nested = responseData['comments'] ??
          responseData['data'] ??
          responseData['items'];

      if (nested is List) {
        rawList = nested;
      } else if (nested is Map<String, dynamic> && nested['items'] is List) {
        rawList = List<dynamic>.from(nested['items'] as List);
      } else {
        rawList = const [];
      }
    } else {
      rawList = const [];
    }

    return rawList
        .map((item) =>
            CommentDto.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);
  }

  @override
  Future<CommentDto> createComment({
    required String trackId,
    required String content,
    String? parentCommentId,
    int? timestampSeconds,
  }) async {
    final response = await dioClient.post(
      ApiConstants.trackCommentsPath(trackId),
      data: {
        'content': content,
        'timestampAt': timestampSeconds ?? 0,
        if (parentCommentId != null) 'parentCommentId': parentCommentId,
      },
    );

    final responseData =
        response.data is String ? jsonDecode(response.data) : response.data;

    final dynamic raw;
    if (responseData is Map<String, dynamic>) {
      raw = responseData['comment'] ?? responseData['data'] ?? responseData;
    } else {
      raw = responseData;
    }

    return CommentDto.fromJson(
      Map<String, dynamic>.from(raw as Map),
    );
  }

  @override
  Future<void> deleteComment(String commentId) async {
    await dioClient.delete(ApiConstants.commentByIdPath(commentId));
  }
}
