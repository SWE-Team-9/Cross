import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/conversation_list_page_entity.dart';
import '../../domain/entities/conversation_messages_page_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/unread_count_entity.dart';
import '../../domain/repositories/messaging_repository.dart';
import '../datasources/messaging_remote_data_source.dart';

class MessagingRepositoryImpl implements MessagingRepository {
  final MessagingRemoteDataSource remoteDataSource;

  MessagingRepositoryImpl(this.remoteDataSource);

  @override
  Future<ConversationListPageEntity> getMyConversations({
    int page = 1,
    int limit = 20,
    bool archived = false,
  }) async {
    final dto = await remoteDataSource.getMyConversations(
      page: page,
      limit: limit,
      archived: archived,
    );

    return dto.toEntity();
  }

  @override
  Future<ConversationMessagesPageEntity> getConversationMessages(
    String conversationId, {
    int page = 1,
    int limit = 50,
  }) async {
    final dto = await remoteDataSource.getConversationMessages(
      conversationId,
      page: page,
      limit: limit,
    );

    return dto.toEntity();
  }

  @override
  Future<ConversationEntity> getConversationMeta(String conversationId) async {
    final dto = await remoteDataSource.getConversationMeta(conversationId);
    return dto.toEntity();
  }

  @override
  Future<ConversationEntity> getOrCreateDirectConversation({
    required String receiverId,
  }) async {
    final dto = await remoteDataSource.getOrCreateDirectConversation(
      receiverId: receiverId,
    );

    return dto.toEntity();
  }

  @override
  Future<MessageEntity> sendTextMessage({
    required String receiverId,
    required String text,
  }) async {
    final dto = await remoteDataSource.sendTextMessage(
      receiverId: receiverId,
      text: text,
    );

    return dto.toEntity();
  }

  @override
  Future<MessageEntity> shareTrack({
    required String receiverId,
    required String trackId,
    String? text,
  }) async {
    final dto = await remoteDataSource.shareTrack(
      receiverId: receiverId,
      trackId: trackId,
      text: text,
    );

    return dto.toEntity();
  }

  @override
  Future<MessageEntity> sharePlaylist({
    required String receiverId,
    required String playlistId,
    String? text,
  }) async {
    final dto = await remoteDataSource.sharePlaylist(
      receiverId: receiverId,
      playlistId: playlistId,
      text: text,
    );

    return dto.toEntity();
  }

  @override
  Future<UnreadCountEntity> getUnreadCount() async {
    final dto = await remoteDataSource.getUnreadCount();
    return dto.toEntity();
  }

  @override
  Future<void> markConversationAsRead(String conversationId) {
    return remoteDataSource.markConversationAsRead(conversationId);
  }

  @override
  Future<void> markConversationAsUnread(String conversationId) {
    return remoteDataSource.markConversationAsUnread(conversationId);
  }

  @override
  Future<void> archiveConversation(String conversationId) {
    return remoteDataSource.archiveConversation(conversationId);
  }

  @override
  Future<void> unarchiveConversation(String conversationId) {
    return remoteDataSource.unarchiveConversation(conversationId);
  }

  @override
  Future<void> deleteMessage(String messageId) {
    return remoteDataSource.deleteMessage(messageId);
  }
}
