import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_list_page_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_messages_page_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_type.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/participant_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/unread_count_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/repositories/messaging_repository.dart';

class FakeMessagingRepository implements MessagingRepository {
  String? lastConversationId;
  String? lastMessageId;
  String? lastReceiverId;
  String? lastText;
  String? lastTrackId;
  String? lastPlaylistId;
  int? lastPage;
  int? lastLimit;
  bool? lastArchived;

  final participant = const ParticipantEntity(
    id: 'user-1',
    displayName: 'Listener One',
    handle: '@listener',
    avatarUrl: null,
  );

  late final conversation = ConversationEntity(
    conversationId: 'conversation-1',
    participant: participant,
    lastMessage: null,
    unreadCount: 0,
  );

  late final message = MessageEntity(
    id: 'message-1',
    conversationId: 'conversation-1',
    senderId: 'sender-1',
    receiverId: 'receiver-1',
    type: MessageType.text,
    text: 'Hello',
    isRead: false,
    createdAt: DateTime.utc(2026, 4, 30),
    sharedTrack: null,
    sharedPlaylist: null,
  );

  @override
  Future<void> archiveConversation(String conversationId) async {
    lastConversationId = conversationId;
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    lastMessageId = messageId;
  }

  @override
  Future<ConversationMessagesPageEntity> getConversationMessages(
    String conversationId, {
    int page = 1,
    int limit = 50,
  }) async {
    lastConversationId = conversationId;
    lastPage = page;
    lastLimit = limit;

    return ConversationMessagesPageEntity(
      conversationId: conversationId,
      page: page,
      limit: limit,
      messages: <MessageEntity>[message],
    );
  }

  @override
  Future<ConversationEntity> getConversationMeta(String conversationId) async {
    lastConversationId = conversationId;
    return conversation;
  }

  @override
  Future<ConversationListPageEntity> getMyConversations({
    int page = 1,
    int limit = 20,
    bool archived = false,
  }) async {
    lastPage = page;
    lastLimit = limit;
    lastArchived = archived;

    return ConversationListPageEntity(
      conversations: <ConversationEntity>[conversation],
      page: page,
      limit: limit,
      total: 1,
      hasMore: false,
    );
  }

  @override
  Future<ConversationEntity> getOrCreateDirectConversation({
    required String receiverId,
  }) async {
    lastReceiverId = receiverId;
    return conversation;
  }

  @override
  Future<UnreadCountEntity> getUnreadCount() async {
    return const UnreadCountEntity(count: 3);
  }

  @override
  Future<void> markConversationAsRead(String conversationId) async {
    lastConversationId = conversationId;
  }

  @override
  Future<void> markConversationAsUnread(String conversationId) async {
    lastConversationId = conversationId;
  }

  @override
  Future<MessageEntity> sendTextMessage({
    required String receiverId,
    required String text,
  }) async {
    lastReceiverId = receiverId;
    lastText = text;
    return message;
  }

  @override
  Future<MessageEntity> sharePlaylist({
    required String receiverId,
    required String playlistId,
    String? text,
  }) async {
    lastReceiverId = receiverId;
    lastPlaylistId = playlistId;
    lastText = text;
    return message;
  }

  @override
  Future<MessageEntity> shareTrack({
    required String receiverId,
    required String trackId,
    String? text,
  }) async {
    lastReceiverId = receiverId;
    lastTrackId = trackId;
    lastText = text;
    return message;
  }

  @override
  Future<void> unarchiveConversation(String conversationId) async {
    lastConversationId = conversationId;
  }
}

void main() {
  group('MessagingRepository contract', () {
    late FakeMessagingRepository repository;

    setUp(() {
      repository = FakeMessagingRepository();
    });

    test('getMyConversations exposes default arguments', () async {
      final result = await repository.getMyConversations();

      expect(result.conversations, hasLength(1));
      expect(repository.lastPage, 1);
      expect(repository.lastLimit, 20);
      expect(repository.lastArchived, isFalse);
    });

    test('getConversationMessages exposes default arguments', () async {
      final result = await repository.getConversationMessages('conversation-1');

      expect(result.conversationId, 'conversation-1');
      expect(repository.lastConversationId, 'conversation-1');
      expect(repository.lastPage, 1);
      expect(repository.lastLimit, 50);
    });

    test('send and share methods expose expected parameters', () async {
      await repository.sendTextMessage(
        receiverId: 'receiver-1',
        text: 'Hello',
      );

      expect(repository.lastReceiverId, 'receiver-1');
      expect(repository.lastText, 'Hello');

      await repository.shareTrack(
        receiverId: 'receiver-2',
        trackId: 'track-1',
        text: 'Track text',
      );

      expect(repository.lastReceiverId, 'receiver-2');
      expect(repository.lastTrackId, 'track-1');
      expect(repository.lastText, 'Track text');

      await repository.sharePlaylist(
        receiverId: 'receiver-3',
        playlistId: 'playlist-1',
        text: 'Playlist text',
      );

      expect(repository.lastReceiverId, 'receiver-3');
      expect(repository.lastPlaylistId, 'playlist-1');
      expect(repository.lastText, 'Playlist text');
    });
  });
}
