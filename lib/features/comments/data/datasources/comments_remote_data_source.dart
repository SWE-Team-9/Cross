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

    final rawList = (responseData['comments'] ??
        responseData['data'] ??
        responseData['items'] ??
        responseData) as List<dynamic>;

    return rawList
        .map((item) => CommentDto.fromJson(Map<String, dynamic>.from(item)))
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
        if (parentCommentId != null) 'parent_comment_id': parentCommentId,
        if (timestampSeconds != null) 'timestamp_seconds': timestampSeconds,
      },
    );

    final responseData =
        response.data is String ? jsonDecode(response.data) : response.data;

    return CommentDto.fromJson(
      Map<String, dynamic>.from(
          responseData['comment'] ?? responseData['data'] ?? responseData),
    );
  }

  @override
  Future<void> deleteComment(String commentId) async {
    await dioClient.delete(ApiConstants.commentByIdPath(commentId));
  }
}
