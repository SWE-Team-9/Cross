import 'message_entity.dart';
import 'participant_entity.dart';

class ConversationEntity {
  final String conversationId;
  final ParticipantEntity participant;
  final MessageEntity? lastMessage;
  final int unreadCount;

  final DateTime? updatedAt;
  final bool isArchived;
  final bool isBlockedByMe;
  final bool hasBlockedMe;
  final bool canMessage;
  final String? blockReason;

  const ConversationEntity({
    required this.conversationId,
    required this.participant,
    required this.lastMessage,
    required this.unreadCount,
    this.updatedAt,
    this.isArchived = false,
    this.isBlockedByMe = false,
    this.hasBlockedMe = false,
    this.canMessage = true,
    this.blockReason,
  });

  ConversationEntity copyWith({
    String? conversationId,
    ParticipantEntity? participant,
    MessageEntity? lastMessage,
    bool clearLastMessage = false,
    int? unreadCount,
    DateTime? updatedAt,
    bool clearUpdatedAt = false,
    bool? isArchived,
    bool? isBlockedByMe,
    bool? hasBlockedMe,
    bool? canMessage,
    String? blockReason,
    bool clearBlockReason = false,
  }) {
    return ConversationEntity(
      conversationId: conversationId ?? this.conversationId,
      participant: participant ?? this.participant,
      lastMessage:
          clearLastMessage ? null : (lastMessage ?? this.lastMessage),
      unreadCount: unreadCount ?? this.unreadCount,
      updatedAt: clearUpdatedAt ? null : (updatedAt ?? this.updatedAt),
      isArchived: isArchived ?? this.isArchived,
      isBlockedByMe: isBlockedByMe ?? this.isBlockedByMe,
      hasBlockedMe: hasBlockedMe ?? this.hasBlockedMe,
      canMessage: canMessage ?? this.canMessage,
      blockReason:
          clearBlockReason ? null : (blockReason ?? this.blockReason),
    );
  }
}