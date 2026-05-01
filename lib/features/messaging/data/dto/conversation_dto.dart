import '../../domain/entities/conversation_entity.dart';
import 'message_dto.dart';
import 'participant_dto.dart';

class ConversationDto {
  final String conversationId;
  final ParticipantDto participant;
  final MessageDto? lastMessage;
  final int unreadCount;

  final DateTime? updatedAt;
  final bool isArchived;
  final bool isBlockedByMe;
  final bool hasBlockedMe;
  final bool canMessage;
  final String? blockReason;

  const ConversationDto({
    required this.conversationId,
    required this.participant,
    required this.lastMessage,
    required this.unreadCount,
    required this.updatedAt,
    required this.isArchived,
    required this.isBlockedByMe,
    required this.hasBlockedMe,
    required this.canMessage,
    required this.blockReason,
  });

  factory ConversationDto.fromJson(Map<String, dynamic> json) {
    final participantRaw = json['participant'] ??
        json['otherUser'] ??
        json['user'] ??
        json['receiver'];

    return ConversationDto(
      conversationId:
          (json['conversationId'] ?? json['id'] ?? json['_id'] ?? '')
              .toString(),
      participant: ParticipantDto.fromJson(_asMap(participantRaw)),
      lastMessage: _messageOrNull(json['lastMessage'] ?? json['last_message']),
      unreadCount: _toInt(json['unreadCount'] ?? json['unread_count']) ?? 0,
      updatedAt:
          _dateOrNull(json['updatedAt'] ?? json['updated_at']),
      isArchived: _toBool(json['isArchived'] ?? json['is_archived']) ?? false,
      isBlockedByMe:
          _toBool(json['isBlockedByMe'] ?? json['is_blocked_by_me']) ?? false,
      hasBlockedMe:
          _toBool(json['hasBlockedMe'] ?? json['has_blocked_me']) ?? false,
      canMessage: _toBool(json['canMessage'] ?? json['can_message']) ?? true,
      blockReason: (json['blockReason'] ?? json['block_reason'])?.toString(),
    );
  }

  ConversationEntity toEntity() {
    return ConversationEntity(
      conversationId: conversationId,
      participant: participant.toEntity(),
      lastMessage: lastMessage?.toEntity(),
      unreadCount: unreadCount,
      updatedAt: updatedAt,
      isArchived: isArchived,
      isBlockedByMe: isBlockedByMe,
      hasBlockedMe: hasBlockedMe,
      canMessage: canMessage,
      blockReason: blockReason,
    );
  }

  static MessageDto? _messageOrNull(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return MessageDto.fromJson(value);
    if (value is Map)
      return MessageDto.fromJson(Map<String, dynamic>.from(value));
    return null;
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);

    return const <String, dynamic>{};
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static bool? _toBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    final normalized = value.toString().toLowerCase().trim();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
    return null;
  }

  static DateTime? _dateOrNull(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
