import '../entities/conversation_entity.dart';
import '../entities/conversation_list_page_entity.dart';
import '../entities/conversation_messages_page_entity.dart';
import '../entities/message_entity.dart';
import '../entities/unread_count_entity.dart';

abstract class MessagingRepository {
  Future<ConversationListPageEntity> getMyConversations({
    int page = 1,
    int limit = 20,
    bool archived = false,
  });

  Future<ConversationMessagesPageEntity> getConversationMessages(
    String conversationId, {
    int page = 1,
    int limit = 50,
  });

  Future<ConversationEntity> getConversationMeta(String conversationId);

  Future<ConversationEntity> getOrCreateDirectConversation({
    required String receiverId,
  });

  Future<MessageEntity> sendTextMessage({
    required String receiverId,
    required String text,
  });

  Future<MessageEntity> shareTrack({
    required String receiverId,
    required String trackId,
    String? text,
  });

  Future<MessageEntity> sharePlaylist({
    required String receiverId,
    required String playlistId,
    String? text,
  });

  Future<UnreadCountEntity> getUnreadCount();

  Future<void> markConversationAsRead(String conversationId);

  Future<void> markConversationAsUnread(String conversationId);

  Future<void> archiveConversation(String conversationId);

  Future<void> unarchiveConversation(String conversationId);

  Future<void> deleteConversation(String conversationId);

  Future<void> deleteMessage(String messageId);
}
