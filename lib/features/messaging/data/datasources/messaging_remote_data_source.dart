import 'dart:convert';

import '../../../../core/network/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../dto/conversation_dto.dart';
import '../dto/conversation_list_page_dto.dart';
import '../dto/conversation_messages_page_dto.dart';
import '../dto/message_dto.dart';
import '../dto/unread_count_dto.dart';

abstract class MessagingRemoteDataSource {
  Future<ConversationListPageDto> getMyConversations({
    int page = 1,
    int limit = 20,
    bool archived = false,
  });

  Future<ConversationMessagesPageDto> getConversationMessages(
    String conversationId, {
    int page = 1,
    int limit = 50,
  });

  Future<ConversationDto> getConversationMeta(String conversationId);

  Future<ConversationDto> getOrCreateDirectConversation({
    required String receiverId,
  });

  Future<MessageDto> sendTextMessage({
    required String receiverId,
    required String text,
  });

  Future<MessageDto> shareTrack({
    required String receiverId,
    required String trackId,
    String? text,
  });

  Future<MessageDto> sharePlaylist({
    required String receiverId,
    required String playlistId,
    String? text,
  });

  Future<UnreadCountDto> getUnreadCount();

  Future<void> markConversationAsRead(String conversationId);

  Future<void> markConversationAsUnread(String conversationId);

  Future<void> archiveConversation(String conversationId);

  Future<void> unarchiveConversation(String conversationId);

  Future<void> deleteMessage(String messageId);
}

class MessagingRemoteDataSourceImpl implements MessagingRemoteDataSource {
  final DioClient dioClient;

  MessagingRemoteDataSourceImpl(this.dioClient);

  @override
  Future<ConversationListPageDto> getMyConversations({
    int page = 1,
    int limit = 20,
    bool archived = false,
  }) async {
    final response = await dioClient.get(
      ApiConstants.messagingConversationsPath,
      queryParameters: {
        'page': page,
        'limit': limit,
        'archived': archived,
      },
    );

    final responseData =
        response.data is String ? jsonDecode(response.data) : response.data;

    return ConversationListPageDto.fromJson(_asMap(responseData));
  }

  @override
  Future<ConversationMessagesPageDto> getConversationMessages(
    String conversationId, {
    int page = 1,
    int limit = 50,
  }) async {
    final response = await dioClient.get(
      ApiConstants.messagingConversationByIdPath(conversationId),
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );

    final responseData =
        response.data is String ? jsonDecode(response.data) : response.data;

    return ConversationMessagesPageDto.fromJson(_asMap(responseData));
  }

  @override
  Future<ConversationDto> getConversationMeta(String conversationId) async {
    final response = await dioClient.get(
      ApiConstants.messagingConversationMetaPath(conversationId),
    );

    final responseData =
        response.data is String ? jsonDecode(response.data) : response.data;

    return ConversationDto.fromJson(_asMap(responseData));
  }

  @override
  Future<ConversationDto> getOrCreateDirectConversation({
    required String receiverId,
  }) async {
    final response = await dioClient.post(
      ApiConstants.messagingDirectConversationPath,
      data: {
        'receiverId': receiverId,
      },
    );

    final responseData =
        response.data is String ? jsonDecode(response.data) : response.data;

    return ConversationDto.fromJson(_asMap(responseData));
  }

  @override
  Future<MessageDto> sendTextMessage({
    required String receiverId,
    required String text,
  }) async {
    final response = await dioClient.post(
      ApiConstants.messagingBase,
      data: {
        'receiverId': receiverId,
        'text': text,
      },
    );

    final responseData =
        response.data is String ? jsonDecode(response.data) : response.data;

    return MessageDto.fromJson(_asMap(responseData));
  }

  @override
  Future<MessageDto> shareTrack({
    required String receiverId,
    required String trackId,
    String? text,
  }) async {
    final response = await dioClient.post(
      ApiConstants.messagingShareTrackPath,
      data: {
        'receiverId': receiverId,
        'trackId': trackId,
        if (text != null && text.trim().isNotEmpty) 'text': text.trim(),
      },
    );

    final responseData =
        response.data is String ? jsonDecode(response.data) : response.data;

    return MessageDto.fromJson(_asMap(responseData));
  }

  @override
  Future<MessageDto> sharePlaylist({
    required String receiverId,
    required String playlistId,
    String? text,
  }) async {
    final response = await dioClient.post(
      ApiConstants.messagingSharePlaylistPath,
      data: {
        'receiverId': receiverId,
        'playlistId': playlistId,
        if (text != null && text.trim().isNotEmpty) 'text': text.trim(),
      },
    );

    final responseData =
        response.data is String ? jsonDecode(response.data) : response.data;

    return MessageDto.fromJson(_asMap(responseData));
  }

  @override
  Future<UnreadCountDto> getUnreadCount() async {
    final response = await dioClient.get(ApiConstants.messagingUnreadCountPath);

    final responseData =
        response.data is String ? jsonDecode(response.data) : response.data;

    return UnreadCountDto.fromJson(_asMap(responseData));
  }

  @override
  Future<void> markConversationAsRead(String conversationId) async {
    await dioClient.patch(
      ApiConstants.messagingMarkConversationReadPath(conversationId),
    );
  }

  @override
  Future<void> markConversationAsUnread(String conversationId) async {
    await dioClient.patch(
      ApiConstants.messagingMarkConversationUnreadPath(conversationId),
    );
  }

  @override
  Future<void> archiveConversation(String conversationId) async {
    await dioClient.patch(
      ApiConstants.messagingArchiveConversationPath(conversationId),
    );
  }

  @override
  Future<void> unarchiveConversation(String conversationId) async {
    await dioClient.patch(
      ApiConstants.messagingUnarchiveConversationPath(conversationId),
    );
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    await dioClient.delete(
      ApiConstants.messagingMessageByIdPath(messageId),
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);

    throw StateError(
      'Expected a JSON object but got ${value.runtimeType}',
    );
  }
}