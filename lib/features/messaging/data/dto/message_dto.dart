import '../../domain/entities/message_entity.dart';
import '../../domain/entities/message_type.dart';
import 'shared_playlist_dto.dart';
import 'shared_track_dto.dart';

class MessageDto {
  final String id;
  final String conversationId;
  final String? senderId;
  final String? receiverId;
  final MessageType type;
  final String? text;
  final bool isRead;
  final DateTime createdAt;
  final SharedTrackDto? sharedTrack;
  final SharedPlaylistDto? sharedPlaylist;

  const MessageDto({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.type,
    required this.text,
    required this.isRead,
    required this.createdAt,
    this.sharedTrack,
    this.sharedPlaylist,
  });

  factory MessageDto.fromJson(Map<String, dynamic> json) {
    final sharedTrackMap = json['sharedTrack'] is Map
        ? Map<String, dynamic>.from(json['sharedTrack'] as Map)
        : null;

    final sharedPlaylistMap = json['sharedPlaylist'] is Map
        ? Map<String, dynamic>.from(json['sharedPlaylist'] as Map)
        : null;

    return MessageDto(
      id: (json['id'] ?? json['messageId'] ?? json['_id'] ?? '').toString(),
      conversationId:
          (json['conversationId'] ?? json['conversation_id'] ?? '').toString(),
      senderId: _nullableString(json['senderId'] ?? json['sender_id']),
      receiverId: _nullableString(json['receiverId'] ?? json['receiver_id']),
      type: MessageTypeX.fromApi(json['type']),
      text: _nullableString(json['text']),
      isRead: _toBool(json['isRead'] ?? json['is_read']) ?? false,
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      sharedTrack: sharedTrackMap == null
          ? null
          : SharedTrackDto.fromJson(sharedTrackMap),
      sharedPlaylist: sharedPlaylistMap == null
          ? null
          : SharedPlaylistDto.fromJson(sharedPlaylistMap),
    );
  }

  MessageEntity toEntity() {
    return MessageEntity(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      type: type,
      text: text,
      isRead: isRead,
      createdAt: createdAt,
      sharedTrack: sharedTrack?.toEntity(),
      sharedPlaylist: sharedPlaylist?.toEntity(),
    );
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;
    final parsed = value.toString().trim();
    return parsed.isEmpty ? null : parsed;
  }

  static bool? _toBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;

    final normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;

    return null;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.fromMillisecondsSinceEpoch(0).toUtc();
    return DateTime.tryParse(value.toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0).toUtc();
  }
}
