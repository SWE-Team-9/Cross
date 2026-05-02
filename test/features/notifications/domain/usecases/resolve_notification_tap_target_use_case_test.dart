import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/participant_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_type.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/get_or_create_direct_conversation_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_list_page_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_messages_page_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/unread_count_entity.dart';
import 'package:soundcloud_clone/features/notifications/domain/entities/notification_entity.dart';
import 'package:soundcloud_clone/features/notifications/domain/usecases/resolve_notification_tap_target_use_case.dart';
import 'package:soundcloud_clone/features/notifications/domain/entities/notification_tap_target.dart';

class _RepoSuccess implements MessagingRepository {
  final ConversationEntity conversation;
  _RepoSuccess(this.conversation);

  @override
  Future<ConversationEntity> getConversationMeta(String conversationId) {
    throw UnimplementedError();
  }

  @override
  Future<ConversationEntity> getOrCreateDirectConversation(
      {required String receiverId}) async {
    return conversation;
  }

  @override
  Future<ConversationListPageEntity> getMyConversations(
      {int page = 1, int limit = 20, bool archived = false}) {
    throw UnimplementedError();
  }

  @override
  Future<ConversationMessagesPageEntity> getConversationMessages(
      String conversationId,
      {int page = 1,
      int limit = 50}) {
    throw UnimplementedError();
  }

  @override
  Future<MessageEntity> sendTextMessage(
      {required String receiverId, required String text}) {
    throw UnimplementedError();
  }

  @override
  Future<MessageEntity> shareTrack(
      {required String receiverId, required String trackId, String? text}) {
    throw UnimplementedError();
  }

  @override
  Future<MessageEntity> sharePlaylist(
      {required String receiverId, required String playlistId, String? text}) {
    throw UnimplementedError();
  }

  @override
  Future<UnreadCountEntity> getUnreadCount() {
    throw UnimplementedError();
  }

  @override
  Future<void> markConversationAsRead(String conversationId) {
    throw UnimplementedError();
  }

  @override
  Future<void> markConversationAsUnread(String conversationId) {
    throw UnimplementedError();
  }

  @override
  Future<void> archiveConversation(String conversationId) {
    throw UnimplementedError();
  }

  @override
  Future<void> unarchiveConversation(String conversationId) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteMessage(String messageId) {
    throw UnimplementedError();
  }
}

class _RepoThrows implements MessagingRepository {
  @override
  Future<ConversationEntity> getConversationMeta(String conversationId) {
    throw UnimplementedError();
  }

  @override
  Future<ConversationEntity> getOrCreateDirectConversation(
      {required String receiverId}) async {
    throw Exception('failed');
  }

  @override
  Future<ConversationListPageEntity> getMyConversations(
      {int page = 1, int limit = 20, bool archived = false}) {
    throw UnimplementedError();
  }

  @override
  Future<ConversationMessagesPageEntity> getConversationMessages(
      String conversationId,
      {int page = 1,
      int limit = 50}) {
    throw UnimplementedError();
  }

  @override
  Future<MessageEntity> sendTextMessage(
      {required String receiverId, required String text}) {
    throw UnimplementedError();
  }

  @override
  Future<MessageEntity> shareTrack(
      {required String receiverId, required String trackId, String? text}) {
    throw UnimplementedError();
  }

  @override
  Future<MessageEntity> sharePlaylist(
      {required String receiverId, required String playlistId, String? text}) {
    throw UnimplementedError();
  }

  @override
  Future<UnreadCountEntity> getUnreadCount() {
    throw UnimplementedError();
  }

  @override
  Future<void> markConversationAsRead(String conversationId) {
    throw UnimplementedError();
  }

  @override
  Future<void> markConversationAsUnread(String conversationId) {
    throw UnimplementedError();
  }

  @override
  Future<void> archiveConversation(String conversationId) {
    throw UnimplementedError();
  }

  @override
  Future<void> unarchiveConversation(String conversationId) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteMessage(String messageId) {
    throw UnimplementedError();
  }
}

void main() {
  group('ResolveNotificationTapTargetUseCase', () {
    test('comment returns comments tap target', () async {
      final usecase = ResolveNotificationTapTargetUseCase(
        GetOrCreateDirectConversationUseCase(_RepoThrows()),
      );

      final notification = NotificationEntity(
        id: 'n1',
        type: NotificationType.comment,
        message: 'a comment',
        actorId: 'actor1',
        actorDisplayName: 'Actor',
        actorHandle: 'actor',
        actorAvatarUrl: '',
        entityType: 'track',
        entityId: 'track-123',
        trackName: 'Track title',
        isRead: false,
        createdAt: DateTime.now(),
      );

      final target = await usecase.call(notification);
      expect(target, isA<NotificationCommentsTapTarget>());
      expect((target as NotificationCommentsTapTarget).trackId, 'track-123');
    });

    test('message resolves to conversation when getOrCreate succeeds',
        () async {
      final convo = ConversationEntity(
        conversationId: 'conv-1',
        participant: ParticipantEntity(
          id: 'u2',
          displayName: 'User 2',
          handle: 'user2',
          avatarUrl: null,
        ),
        lastMessage: MessageEntity(
          id: 'm1',
          conversationId: 'conv-1',
          senderId: 'u2',
          receiverId: 'me',
          type: MessageType.text,
          text: 'hello',
          isRead: false,
          createdAt: DateTime.now(),
          sharedTrack: null,
          sharedPlaylist: null,
        ),
        unreadCount: 0,
      );

      final usecase = ResolveNotificationTapTargetUseCase(
        GetOrCreateDirectConversationUseCase(_RepoSuccess(convo)),
      );

      final notification = NotificationEntity(
        id: 'n2',
        type: NotificationType.message,
        message: 'dm',
        actorId: 'u2',
        actorDisplayName: 'User 2',
        actorHandle: 'user2',
        actorAvatarUrl: '',
        entityType: 'conversation',
        entityId: 'conv-1',
        trackName: '',
        isRead: false,
        createdAt: DateTime.now(),
      );

      final target = await usecase.call(notification);
      expect(target, isA<NotificationConversationTapTarget>());
      expect(
          (target as NotificationConversationTapTarget)
              .conversation
              .conversationId,
          'conv-1');
    });

    test('message returns null when getOrCreate throws', () async {
      final usecase = ResolveNotificationTapTargetUseCase(
        GetOrCreateDirectConversationUseCase(_RepoThrows()),
      );

      final notification = NotificationEntity(
        id: 'n3',
        type: NotificationType.message,
        message: 'dm',
        actorId: 'uX',
        actorDisplayName: '',
        actorHandle: '',
        actorAvatarUrl: '',
        entityType: 'user',
        entityId: '',
        trackName: '',
        isRead: false,
        createdAt: DateTime.now(),
      );

      final target = await usecase.call(notification);
      expect(target, isNull);
    });

    test('like/follow/repost produce sanitized profile handle', () async {
      final usecase = ResolveNotificationTapTargetUseCase(
        GetOrCreateDirectConversationUseCase(_RepoThrows()),
      );

      final notification = NotificationEntity(
        id: 'n4',
        type: NotificationType.follow,
        message: 'followed',
        actorId: '123',
        actorDisplayName: '',
        actorHandle: '@Good-User!!',
        actorAvatarUrl: '',
        entityType: 'user',
        entityId: '',
        trackName: '',
        isRead: false,
        createdAt: DateTime.now(),
      );

      final target = await usecase.call(notification);
      expect(target, isA<NotificationProfileTapTarget>());
      expect((target as NotificationProfileTapTarget).handle, 'Good-User');
    });
  });
}
